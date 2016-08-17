require 'lptimekeeping/version'
require 'uri'
require 'httparty'
require 'highline/import'
require 'liquidplanner/liquidplanner'

##
module Lptimekeeping
  ## Terminal interface for liquidplanner
  class Terminal
    attr_accessor :workspace, :project, :task, :lp

    def initialize
      if ENV['LP_USERNAME'] && ENV['LP_PASSWORD']
        email, password = ENV['LP_USERNAME'], ENV['LP_PASSWORD']
      else
        email, password = credintials
      end
      @lp = LiquidPlanner.new(email, password)
    end

    def option_prompt
      "\nOptions:\n\t1. Timekeeping\n\t2. List Tasks\n\t3. Exit\n"
    end

    def select_workspace
      workspaces = @lp.workspaces
      ws = workspaces.first
      return ws['id']
    end

    def credintials
      email    = ask("LiquidPlanner email: ")
      password = ask("LiquidPlanner password for #{email}: ") {|q| q.echo = false}
      return email, password
    end

    def scope_project
      projects = @lp.projects(@workspace)
      puts "\nThese are the #{projects.length} projects in your workspace"
      projects.each_with_index do |p, i|
      puts " #{i+1}. #{p['name']}"
      end
      project_selected = projects[ask("Set the project you want to look at:").to_i-1]
      @project = project_selected['id']
    end

    def print_tasks
      tasks = @lp.tasks(@workspace, @project)
      puts "\nTasks:"
      tasks['children'].each_with_index do |t, i|
        puts "\t#{i+1}. #{t['name']} (id: #{t['id']})"
      end
    end

    def scope_task
      tasks = @lp.tasks(@workspace, @project)
      puts "\nTasks:"
      if tasks['children']
        tasks['children'].each_with_index do |t, i|
          puts "\t#{i+1}. #{t['name']} (id: #{t['id']})"
        end
        task_selected = tasks['children'][ask("Set the task you want to choose:").to_i-1]
        @task = task_selected['id']
      else
        puts "This Project has no tasks..."
      end
    end

    def divider
      puts "--------------------------"
    end

    def list_timers
      timers = @lp.timers(@workspace)
      if timers.count > 0
        puts timers
      else
        puts "You currently have no timers running..."
      end
    end

    def clock_in
      @lp.start_timer(@workspace, @task)
    end

    def clock_out
      @lp.stop_timer(@workspace,@task)
      @lp.commit_timer(@workspace,@task)
      @lp.clear_timer(@workspace, @task)
    end

    def is_clocked_in
      if @lp.timers(@workspace).count == 0
        return false
      else
        return true
      end
    end

    def timekeeping
      if is_clocked_in == true
        option = ask("You are clocked in, would you like to clock out?(y/n)")
        if option == "y"
          clock_out
        else
          puts "You were not clocked out"
        end
      else
        divider
        scope_project
        divider
        scope_task
        clock_in
      end
    end

    def start
      account = @lp.account
      puts "You are #{account['user_name']} (#{account['id']})"
      should_prompt = true
      @workspace =  select_workspace
      @task = @lp.current_task(@workspace)
      while should_prompt
        option = ask(option_prompt)
        if option == "1"
          timekeeping
        end
        if option == "2"
          scope_project
          divider
          print_tasks
        end
        # if option == "3"
        #   list_timers
        # end
        if option == "3"
          should_prompt = false
        end
        divider
      end
    end
  end
end
