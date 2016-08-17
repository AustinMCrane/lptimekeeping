# include the versioning file for lptimekeeping
require 'lptimekeeping/version'
# for some reason highline is require for the ask() method
require 'highline/import'
# include our interface for liquidplanner api
require 'liquidplanner/liquidplanner'

module Lptimekeeping
  ## Terminal interface for liquidplanner timekeeping
  # The current method for keeping track of time is through timers that are
  # tied to tasks, so to clock in you set a timer on a task and to clock out
  # you stop the timer and commit the total time for the timer to the task.
  class Terminal
    # accessible class attributes
    attr_accessor :workspace, :project, :task, :lp

    # New Terminal, this asks for the user credintials if the user does not
    # have enviroment variables set for their account info, this feature might
    # get taken out due to some security risks
    def initialize
      # check if the users system has enviroment variables set for their
      # liquid planner credintials
      if ENV['LP_USERNAME'] && ENV['LP_PASSWORD']
        # use the enviroment vars for credintials
        email, password = ENV['LP_USERNAME'], ENV['LP_PASSWORD']
      else
        # ask user for credintials through the command line
        email, password = credintials
      end
      # initialize the instance variable for our liquid planner interface
      @lp = LiquidPlanner.new(email, password)
    end

    # A menu to use for the options available to the user, this is just a string
    # nothing fancy here
    def option_prompt
      "\nOptions:\n\t1. Timekeeping\n\t2. List Tasks\n\t3. Exit\n"
    end

    # Returns the first workspace available in the users workspaces
    # TODO: this could be simplified as a design pattern
    def select_workspace
      # Gets all the users workspaces
      workspaces = @lp.workspaces
      # Gets the first one out of the array
      ws = workspaces.first
      # returns the value for the id of the project
      ws['id']
    end

    # Asks the user for their credintials for liquid planner
    # and returns email, password
    def credintials
      # prompts user for email
      email    = ask('LiquidPlanner email: ')
      # prompts user for password
      password = ask('LiquidPlanner password for #{email}: ') { |q| q.echo = false }
      # return the inputed values
      # TODO: maybe do some validation here?
      return email, password
    end

    def scope_project
      # Get all of the projects for the selected workspace
      projects = @lp.projects(@workspace)
      # Tell the user how many projects were found in the workspace
      puts "\nThese are the #{projects.length} projects in your workspace"
      # for each project in projects print out a description of the options
      projects.each_with_index do |p, i|
        puts " #{i + 1}. #{p['name']} (id: #{p['id']})"
      end
      # get the index of the project, need to -1 here sense we start at 1 and
      # not 0
      index = ask('Set the project you want to look at:').to_i - 1
      # get the selected project out of the array
      project_selected = projects[index]
      # set it as the current scope for project
      @project = project_selected['id']
    end

    # Print out tasks to terminal
    def print_tasks
      # Get all of the tasks
      tasks = @lp.tasks(@workspace, @project)
      puts "\nTasks:"
      tasks['children'].each_with_index do |t, i|
        puts "\t#{i + 1}. #{t['name']} (id: #{t['id']})"
      end
    end

    # Select the task to use for scope
    # TODO: this and print_tasks could be simplified together
    def scope_task
      # Get all of the tasks
      tasks = @lp.tasks(@workspace, @project)
      puts "\nTasks:"
      if tasks['children']
        tasks['children'].each_with_index do |t, i|
          puts "\t#{i + 1}. #{t['name']}"
        end
        index = ask('Set the task you want to choose:').to_i - 1
        task_selected = tasks['children'][index]
        @task = task_selected['id']
      else
        puts 'This Project has no tasks...'
      end
    end

    def divider
      puts '--------------------------'
    end

    def list_timers
      timers = @lp.timers(@workspace)
      if timers.count > 0
        puts timers
      else
        puts 'You currently have no timers running...'
      end
    end

    def clock_in
      @lp.start_timer(@workspace, @task)
    end

    def clock_out
      @lp.stop_timer(@workspace, @task)
      @lp.commit_timer(@workspace, @task)
      @lp.clear_timer(@workspace, @task)
    end

    # TODO: change this to clocked_in?
    # Checks if the user is clocked in based on the user
    # having any running timers
    def is_clocked_in
      if @lp.timers(@workspace).count == 0
        return false
      else
        return true
      end
    end

    # Timekeeping menu option integration function
    # TODO: probably needs simplified and made better
    def timekeeping
      if is_clocked_in == true
        option = ask('You are clocked in, would you like to clock out?(y/n)')
        if option == 'y'
          clock_out
        else
          puts 'You were not clocked out'
        end
      else
        divider
        scope_project
        divider
        scope_task
        clock_in
      end
    end

    # TODO: Simpliy this mess...
    # The main loop for the menu of the terminal application
    # 1. timekeeping
    # 2. list projects and tasks
    # 3. exit program
    def start
      # TODO: could Simpliy this into another setup function
      # Get the users account info to make sure that they have good credintials
      account = @lp.account
      # Show the user a welcome message for successful login
      puts "You are #{account['user_name']} (#{account['id']})"
      # used to decide to stay in menu loop
      should_prompt = true
      # Set default workspace scope
      @workspace =  select_workspace
      # Check if there are any currently clocked in tasks
      @task = @lp.current_task(@workspace)
      # Loop through menu until user exits with option 3
      while should_prompt
        # Prompt user for input based on options menu
        option = ask(option_prompt)
        # User selected timekeeping
        if option == '1'
          timekeeping
        end
        # User selected List Tasks
        if option == '2'
          # TODO: could be simplified
          scope_project
          divider
          print_tasks
        end
        # User selected Exit
        if option == '3'
          # set the condition for while loop to be false for quick exit
          # on next loop back
          should_prompt = false
        end
        # print out an organizational divider
        divider
      end
    end
  end
end
