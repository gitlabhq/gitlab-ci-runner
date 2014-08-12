require 'yaml'

module GitlabCi
  class Workers
    attr_reader :workers

    def initialize
      if File.exists?(workers_path)
        @workers = YAML.load_file(workers_path)
      else
        @workers = {}
      end

    end

    def add_worker(pid, build_data)
      unless pids.include? pid
        pids[pid] = build_data
        write
      end
    end

    def remove_worker(pid)
      if pids.include? pid
        pids.delete pid
        write
      end
    end

    def count
      pids.count
    end

    def pids
      @workers['pid'] ||= Hash.new
    end

    def write
      File.open(workers_path, "w") do |f|
        f.write(@workers.to_yaml)
      end
    end

    def next_runner_id
      cur_ids = pids.map { |pid, data| data[:runner_id] }
      new_ids = (pids.count + 1).times.to_a - cur_ids
      new_ids.first
    end

    private

    def workers_path
      File.join(ROOT_PATH, 'workers.yml')
    end
  end
end
