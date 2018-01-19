class Fluent::MySQLSlowQueryLogOutput < Fluent::Output
  Fluent::Plugin.register_output('mysqlslowquerylog', self)
  include Fluent::HandleTagNameMixin
  require 'digest'

  def configure(conf)
    super
    @slowlogs = {}

    if !@remove_tag_prefix && !@remove_tag_suffix && !@add_tag_prefix && !@add_tag_suffix
      raise ConfigError, "out_myslowquerylog: At least one of option, remove_tag_prefix, remove_tag_suffix, add_tag_prefix or add_tag_suffix is required to be set."
    end
  end

  def start
    super
  end

  def shutdown
    super
  end

  def emit(tag, es, chain)
    if !@slowlogs[:"#{tag}"].instance_of?(Array)
      @slowlogs[:"#{tag}"] = []
    end
    es.each do |time, record|
      concat_messages(tag, time, record)
    end

    chain.next
  end

  def concat_messages(tag, time, record)
    record.each do |key, value|
      @slowlogs[:"#{tag}"] << value
      if value.end_with?(';') && !value.upcase.start_with?('USE ', 'SET TIMESTAMP=')
        parse_message(tag, time)
      end
    end
  end

  REGEX1 = /^#? User\@Host:\s+(\S+)\s+\@\s+(\S+).*/
  REGEX2 = /^# Query_time: ([0-9.]+)\s+Lock_time: ([0-9.]+)\s+Rows_sent: ([0-9.]+)\s+Rows_examined: ([0-9.]+).*/
  REGEX3 = /^use\s+(\S+);/
  REGEX4 = /^SET\s+timestamp=(\d+);/
  def parse_message(tag, time)
    record = {}
    date   = nil

    # Skip the message that is output when after flush-logs or restart mysqld.
    # e.g.) /usr/sbin/mysqld, Version: 5.5.28-0ubuntu0.12.04.2-log ((Ubuntu)). started with:
    begin
      message = @slowlogs[:"#{tag}"].shift
    end while !message.start_with?('#')

    if message.start_with?('# Time: ')
      date    = Time.parse(message[8..-1].strip)
      message = @slowlogs[:"#{tag}"].shift
    end

    message =~ REGEX1
    record['user'] = $1
    record['host'] = $2
    @hash_str = record['user'].to_s + record['host'].to_s
    message = @slowlogs[:"#{tag}"].shift

    message =~ REGEX2
    record['query_time']    = $1.to_f
    record['lock_time']     = $2.to_f
    record['rows_sent']     = $3.to_i
    record['rows_examined'] = $4.to_i
    message = @slowlogs[:"#{tag}"].shift

    if message.start_with?('use ')
      message =~ REGEX3
      record['database'] = $1
      message = @slowlogs[:"#{tag}"].shift
    else
      record['database'] = 'no_database_logged'
    end

    if message.start_with?('SET timestamp=')
      message =~ REGEX4
      record['set_timestamp'] = $1
      @hash_str << record['set_timestamp'].to_s
    end

    @sql_line = @slowlogs[:"#{tag}"].map {|m| m.strip}.join(' ')
    record['sql'] = @sql_line.to_s
    @hash_str << @sql_line.to_s

    record['hash_id'] = Digest::SHA1.hexdigest(@hash_str)

    time = date.to_i if date
    flush_emit(tag, time, record)
  end

  def flush_emit(tag, time, record)
    @slowlogs[:"#{tag}"].clear
    _tag = tag.clone
    filter_record(_tag, time, record)
    if tag != _tag
      router.emit(_tag, time, record)
    else
      $log.warn "Can not emit message because the tag has not changed. Dropped record #{record}"
    end
  end
end
