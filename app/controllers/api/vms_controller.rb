module Api
  class VmsController < BaseController
    include Subcollections::Disks
    include Subcollections::Compliances
    include Subcollections::Tags
    include Subcollections::Policies
    include Subcollections::PolicyProfiles
    include Subcollections::Accounts
    include Subcollections::CustomAttributes
    include Subcollections::SecurityGroups
    include Subcollections::Software
    include Subcollections::Snapshots
    include Subcollections::MetricRollups
    include Subcollections::Cdroms
    extend Api::Mixins::CentralAdmin

    DEFAULT_ROLE = 'ems_operations'.freeze
    RELATIONSHIP_COLLECTIONS = %w[vms templates].freeze
    VALID_EDIT_ATTRS = %w[description name child_resources parent_resource].freeze

    def start_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for starting a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Starting #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "start")
        result = start_vm(vm) if result[:success]
        result
      end
    end
    central_admin :start_resource, :start

    def stop_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for stopping a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Stopping #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "stop")
        result = stop_vm(vm) if result[:success]
        result
      end
    end
    central_admin :stop_resource, :stop

    def suspend_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for suspending a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Suspending #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "suspend")
        result = suspend_vm(vm) if result[:success]
        result
      end
    end
    central_admin :suspend_resource, :suspend

    def pause_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for pausing a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Pausing #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "pause")
        result = pause_vm(vm) if result[:success]
        result
      end
    end

    def shelve_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for shelving a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Shelving #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "shelve")
        result = shelve_vm(vm) if result[:success]
        result
      end
    end

    def shelve_offload_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for shelve-offloading a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Shelve-offloading #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "shelve_offload")
        result = shelve_offload_vm(vm) if result[:success]
        result
      end
    end

    def edit_resource(type, id, data)
      attrs = validate_edit_data(data)
      parent, children = build_parent_children(data)
      resource_search(id, type, collection_class(type)).tap do |vm|
        vm.update_attributes!(attrs)
        vm.replace_children(children)
        vm.set_parent(parent)
      end
    rescue => err
      raise BadRequestError, "Cannot edit VM - #{err}"
    end

    def delete_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for deleting a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Deleting #{vm_ident(vm)}")

        destroy_vm(vm)
      end
    end

    def set_owner_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for setting the owner of a #{type} resource" unless id

      owner = data.blank? ? "" : data["owner"].strip
      raise BadRequestError, "Must specify an owner" if owner.blank?

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Setting owner of #{vm_ident(vm)}")

        set_owner_vm(vm, owner)
      end
    end

    def add_lifecycle_event_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for adding a Lifecycle Event to a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Adding Lifecycle Event to #{vm_ident(vm)}")

        add_lifecycle_event_vm(vm, lifecycle_event_from_data(data))
      end
    end

    def scan_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for scanning a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Scanning #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "scan")
        result = scan_vm(vm) if result[:success]
        result
      end
    end

    def add_event_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for adding an event to a #{type} resource" unless id

      data ||= {}

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Adding Event to #{vm_ident(vm)}")

        vm_event(vm, data["event_type"].to_s, data["event_message"].to_s, data["event_time"].to_s)
      end
    end

    def retire_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for retiring a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Retiring #{vm_ident(vm)}")
        retire_vm(vm, id, data)
      end
    end

    def reset_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for resetting a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Resetting #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "reset")
        result = reset_vm(vm) if result[:success]
        result
      end
    end
    central_admin :reset_resource, :reset

    def reboot_guest_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for rebooting a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Rebooting #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "reboot_guest")
        result = reboot_guest_vm(vm) if result[:success]
        result
      end
    end
    central_admin :reboot_guest_resource, :reboot_guest

    def shutdown_guest_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for shutting down a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Shutting down #{vm_ident(vm)}")

        result = validate_vm_for_action(vm, "shutdown_guest")
        result = shutdown_guest_vm(vm) if result[:success]
        result
      end
    end
    central_admin :shutdown_guest_resource, :shutdown_guest

    def refresh_resource(type, id = nil, _data = nil)
      raise BadRequestError, "Must specify an id for refreshing a #{type} resource" unless id

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Refreshing #{vm_ident(vm)}")
        refresh_vm(vm)
      end
    end

    def request_console_resource(type, id = nil, data = nil)
      raise BadRequestError, "Must specify an id for requesting a console for a #{type} resource" unless id

      # NOTE:
      # for Future ?:
      #   data ||= {}
      #   protocol = data["protocol"] || "mks"
      # However, there are different entitlements for the different protocol as per miq_product_feature,
      # so we may go for different action, i.e. request_console_vnc
      # protocol = "mks"
      protocol = data["protocol"] || "vnc"

      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Requesting Console #{vm_ident(vm)}")

        result = validate_vm_for_remote_console(vm, protocol)
        result = request_console_vm(vm, protocol) if result[:success]
        result
      end
    end

    def set_miq_server_resource(type, id, data)
      vm = resource_search(id, type, collection_class(type))

      miq_server = if data['miq_server'].empty?
                     nil
                   else
                     miq_server_id = parse_id(data['miq_server'], :servers)
                     raise 'Must specify a valid miq_server href or id' unless miq_server_id
                     resource_search(miq_server_id, :servers, collection_class(:servers))
                   end

      vm.miq_server = miq_server
      action_result(true, "#{miq_server_message(miq_server)} for #{vm_ident(vm)}")
    rescue => err
      action_result(false, "Failed to set miq_server - #{err}")
    end

    def request_retire_resource(type, id, _data = nil)
      api_action(type, id) do |klass|
        vm = resource_search(id, type, klass)
        api_log_info("Retiring request of vm #{vm_ident(vm)}")
        request_retire(vm)
      end
    end

    private

    def miq_server_message(miq_server)
      miq_server ? "Set miq_server id:#{miq_server.id}" : "Removed miq_server"
    end

    def validate_edit_data(data)
      invalid_keys = data.keys - VALID_EDIT_ATTRS - valid_custom_attrs
      raise BadRequestError, "Cannot edit values #{invalid_keys.join(', ')}" if invalid_keys.present?
      data.except('parent_resource', 'child_resources')
    end

    def build_parent_children(data)
      children = if data.key?('child_resources')
                   data['child_resources'].collect do |child|
                     fetch_relationship(child['href'])
                   end
                 end

      parent = if data.key?('parent_resource')
                 fetch_relationship(data['parent_resource']['href'])
               end

      [parent, Array(children)]
    end

    def fetch_relationship(href)
      href = Href.new(href)
      raise "Invalid relationship type #{href.subject}" unless RELATIONSHIP_COLLECTIONS.include?(href.subject)
      resource_search(href.subject_id, href.subject, collection_class(href.subject))
    end

    def valid_custom_attrs
      Vm.virtual_attribute_names.select { |name| name =~ /custom_\d/ }
    end

    def vm_ident(vm)
      "VM id:#{vm.id} name:'#{vm.name}'"
    end

    def validate_vm_for_action(vm, action)
      if vm.respond_to?("supports_#{action}?")
        action_result(vm.public_send("supports_#{action}?"), vm.unsupported_reason(action.to_sym))
      else
        validation = vm.send("validate_#{action}")
        action_result(validation[:available], validation[:message].to_s)
      end
    end

    def validate_vm_for_remote_console(vm, protocol = nil)
      protocol ||= "mks"
      vm.validate_remote_console_acquire_ticket(protocol)
      action_result(true, "")
    rescue MiqException::RemoteConsoleNotSupportedError => err
      action_result(false, err.message)
    end

    def start_vm(vm)
      desc = "#{vm_ident(vm)} starting"
      task_id = queue_object_action(vm, desc, queue_options("start", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def stop_vm(vm)
      desc = "#{vm_ident(vm)} stopping"
      task_id = queue_object_action(vm, desc, queue_options("stop", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def suspend_vm(vm)
      desc = "#{vm_ident(vm)} suspending"
      task_id = queue_object_action(vm, desc, queue_options("suspend", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def pause_vm(vm)
      desc = "#{vm_ident(vm)} pausing"
      task_id = queue_object_action(vm, desc, queue_options("pause", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def shelve_vm(vm)
      desc = "#{vm_ident(vm)} shelving"
      task_id = queue_object_action(vm, desc, queue_options("shelve", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def shelve_offload_vm(vm)
      desc = "#{vm_ident(vm)} shelve-offloading"
      task_id = queue_object_action(vm, desc, queue_options("shelve_offload", DEFAULT_ROLE))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def destroy_vm(vm)
      desc = "#{vm_ident(vm)} deleting"
      task_id = queue_object_action(vm, desc, queue_options("destroy"))
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def set_owner_vm(vm, owner)
      desc = "#{vm_ident(vm)} setting owner to '#{owner}'"
      user = User.lookup_by_identity(owner)
      raise "Invalid user #{owner} specified" unless user
      vm.evm_owner = user
      vm.miq_group = user.current_group unless user.nil?
      vm.save!
      action_result(true, desc)
    rescue => err
      action_result(false, err.to_s)
    end

    def add_lifecycle_event_vm(vm, lifecycle_event)
      desc = "#{vm_ident(vm)} adding lifecycle event=#{lifecycle_event['event']} message=#{lifecycle_event['message']}"
      event = LifecycleEvent.create_event(vm, lifecycle_event)
      action_result(event.present?, desc)
    rescue => err
      action_result(false, err.to_s)
    end

    def lifecycle_event_from_data(data)
      data ||= {}
      data = data.slice("event", "status", "message", "created_by")
      data.keys.each { |k| data[k] = data[k].to_s }
      data
    end

    def scan_vm(vm)
      desc = "#{vm_ident(vm)} scanning"
      task_id = queue_object_action(vm, desc, :method_name => "scan", :role => "smartstate")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def vm_event(vm, event_type, event_message, event_time)
      desc = "Adding Event type=#{event_type} message=#{event_message}"
      event_timestamp = event_time.blank? ? Time.now.utc : event_time.to_time(:utc)

      vm.add_ems_event(event_type, event_message, event_timestamp)
      action_result(true, desc)
    rescue => err
      action_result(false, err.to_s)
    end

    def retire_vm(vm, id, data)
      desc = "#{vm_ident(vm)} retiring"
      desc << " on #{data['date']}" if Hash(data)['date'].present?
      generic_retire_resource(:vms, id, data)
      action_result(true, desc)
    rescue => err
      action_result(false, err.to_s)
    end

    def reset_vm(vm)
      desc = "#{vm_ident(vm)} resetting"
      task_id = queue_object_action(vm, desc, :method_name => "reset", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def refresh_vm(vm)
      desc = "#{vm_ident(vm)} refreshing"
      task_id = queue_object_action(vm, desc, :method_name => "refresh_ems", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def shutdown_guest_vm(vm)
      desc = "#{vm_ident(vm)} shutting down"
      task_id = queue_object_action(vm, desc, :method_name => "shutdown_guest", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def reboot_guest_vm(vm)
      desc = "#{vm_ident(vm)} rebooting"
      task_id = queue_object_action(vm, desc, :method_name => "reboot_guest", :role => "ems_operations")
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def request_console_vm(vm, protocol)
      desc = "#{vm_ident(vm)} requesting console"
      task_id = queue_object_action(vm, desc,
                                    :method_name => "remote_console_acquire_ticket",
                                    :role        => "ems_operations",
                                    :args        => [User.current_user.userid, MiqServer.my_server.id, protocol])
      # NOTE:
      # we are queuing the :remote_console_acquire_ticket and returning the task id and href.
      #
      # The remote console ticket/info can be stashed in the task's context_data by the *_acquire_ticket method
      # context_data is returned as part of the task i.e. GET /api/tasks/:id
      action_result(true, desc, :task_id => task_id)
    rescue => err
      action_result(false, err.to_s)
    end

    def request_retire(virtual_machine)
      desc = "#{vm_ident(virtual_machine)} request retire"

      task_id = queue_object_action(virtual_machine, desc, :method_name => "make_retire_request", :role => "automate", :args => [User.current_user.id])
      action_result(true, desc, :task_id => task_id)
    rescue StandardError => err
      action_result(false, err.to_s)
    end
  end
end
