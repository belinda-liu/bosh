module Bosh::Director
  module Jobs
    module BaseJob

      def perform(task_id, *args)
        task = Models::Task[task_id]
        raise TaskNotFound.new(task_id) if task.nil?

        logger = Logger.new(task.output)
        logger.level = Config.logger.level
        logger.formatter = ThreadFormatter.new
        logger.info("Starting task: #{task_id}")
        Config.logger = logger

        with_thread_name("task:#{task_id}") do
          begin
            logger.info("Creating job")
            job = self.send(:new, *args)

            logger.info("Performing task: #{task_id}")
            task.state = :processing
            task.timestamp = Time.now.to_i
            task.save!
            result = job.perform

            logger.info("Done")
            task.state = :done
            task.result = result
            task.timestamp = Time.now.to_i
            task.save!
          rescue Exception => e
            logger.error("#{e} - #{e.backtrace.join("\n")}")
            task.state = :error
            task.result = e.to_s
            task.timestamp = Time.now.to_i
            task.save!
          end
        end
      end

    end
  end
end
