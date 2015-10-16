module JobsHelper
  def job_page_title
    "#{@project.name} deploy (#{@job.status})"
  end

  def job_active?
    @job.active? && (JobExecution.find_by_id(@job.id) || JobExecution.enabled)
  end
end
