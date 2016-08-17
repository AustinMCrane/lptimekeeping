##
class Lptimekeeping::LiquidPlanner
  include HTTParty

  base_uri 'https://app.liquidplanner.com/api'
  format :json

  def initialize(email, password)
    @opts = { :basic_auth => { :username => email, :password => password },
              :headers    => { 'content-type' => 'application/json' },
            }
  end

  def get(url, options={})
    self.class.get(url, options.merge(@opts))
  end

  def post(url, options={})
    options[:body] = options[:body].to_json if options[:body]
    self.class.post(url, options.merge(@opts))
  end

  def put(url, options={})
    options[:body] = options[:body].to_json if options[:body]
    self.class.put(url, options.merge(@opts))
  end

  def account
    get('/account')
  end

  def workspaces
    get('/workspaces')
  end

  def projects(workspace_id)
    get("/workspaces/#{workspace_id}/projects")
  end

  def tasks(workspace_id, project_id)
    get("/workspaces/#{workspace_id}/treeitems/#{project_id}?depth=-1&leaves=true")
  end

  def start_timer(workspace_id, task_id)
    post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/start")
  end

  def stop_timer(workspace_id, task_id)
    post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/stop")
  end

  def clear_timer(workspace_id, task_id)
    post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/clear")
  end

  def commit_timer(workspace_id, task_id)
    post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/commit", :body => {:activity_id => 226386})
  end

  def timers(workspace_id)
    get("/workspaces/#{workspace_id}/my_timers")
  end

  def current_task(workspace_id)
    timers = get("/workspaces/#{workspace_id}/my_timers")
    if timers.count > 0
      return timers.first['item_id']
    else
      return nil
    end
  end

  # def create_task(data)
  #   options = { :body => { :task => data } }
  #   post("/workspaces/#{workspace_id}/tasks", :body => { :task => data })
  # end
  #
  # def update_task(data)
  #   options = { :body => { :task => data } }
  #   put("/workspaces/#{workspace_id}/tasks/#{data['id']}", :body => { :task => data })
  # end

end
