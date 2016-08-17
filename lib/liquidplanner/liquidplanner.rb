require 'uri'
require 'httparty'
module Lptimekeeping
  ## An interface for the liquid planner api
  # at its current state it is non distructive so it is pretty safe to use
  class LiquidPlanner
    # The library used to make HTTP requests to liquid planner
    include HTTParty
    # The origin of the liquid planner api
    base_uri 'https://app.liquidplanner.com/api'
    # make all data formats comming in json
    format :json

    # Requires some basic authentication to make requests to liquidplanner
    # so we init with credintials
    def initialize(email, password)
      # opts is now a class property, it is a hash
      @opts = { basic_auth: { username: email, password: password },
                headers: { 'content-type' => 'application/json' } }
    end

    # Governed get request, all requests add basic auth from the opt
    def get(url, options = {})
      self.class.get(url, options.merge(@opts)) # merge opts to request headers
    end

    # Governed post request, all requests add basic auth from the opt
    def post(url, options = {})
      # grabs the body from the options param to use for data in post request
      options[:body] = options[:body].to_json if options[:body]
      self.class.post(url, options.merge(@opts)) # merge opts to request headers
    end

    # Governed put request, all requests add basic auth from the opt
    def put(url, options = {})
      # grabs the body from the options param to use for data in post request
      options[:body] = options[:body].to_json if options[:body]
      self.class.put(url, options.merge(@opts)) # merge opts to request headers
    end

    # Get user account info
    # An example output can be found on page 7 of LP api documentation
    def account
      get('/account')
    end

    # Get all of the users workspaces
    # gets a list of workspaces that a user has access too, workspaces are
    # important to give scope to other requests
    def workspaces
      get('/workspaces')
    end

    # Get all projects for a workspace, given that the user has access to the
    # workspace
    def projects(workspace_id)
      get("/workspaces/#{workspace_id}/projects")
    end

    # Get all tree items under a project, this includes folders and tasks
    def tasks(workspace_id, project_id)
      get("/workspaces/#{workspace_id}/treeitems/#{project_id}?depth=-1&leaves=true")
    end

    # Starts a timer on a task by task_id
    def start_timer(workspace_id, task_id)
      post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/start")
    end

    # Stops a timer that is running on a task by task_id
    def stop_timer(workspace_id, task_id)
      post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/stop")
    end

    # Clear a timer that is running on a task by task_id
    def clear_timer(workspace_id, task_id)
      post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/clear")
    end

    # Commit a timer, this adds the total time on the timer to the timesheet,
    # commit by task_id
    def commit_timer(workspace_id, task_id)
      post("/workspaces/#{workspace_id}/tasks/#{task_id}/timer/commit", body: { activity_id: 226386 })
    end

    # Gets all of the currently running timers for user
    def timers(workspace_id)
      get("/workspaces/#{workspace_id}/my_timers")
    end

    # Current Task being worked on, if there is not task nil is returned
    # this is not a built in feature to liquid planner but helps
    def current_task(workspace_id)
      timers = get("/workspaces/#{workspace_id}/my_timers")
      # TODO: figure out a good way to do one line if statements in ruby,
      # lexical?
      if timers.count > 0
        return timers.first['item_id']
      else
        return nil
      end
    end
  end
end
