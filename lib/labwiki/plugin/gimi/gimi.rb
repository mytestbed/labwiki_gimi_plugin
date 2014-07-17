require 'omf-web/session_store'

class LabWiki::Gimi < OMF::Base::LObject
  include Singleton

  def initialize
    @opts = LabWiki::Configurator['plugins/gimi']
    debug "GIMI options: #{@opts}"
  end

  def on_session_init
    return unless @opts
    construct_useable_user_data
  end

  def on_session_close
    #TODO What to do?
  end

  def construct_useable_user_data
    user = OMF::Web::SessionStore[:data, :user]
    if (urn = user['http://geni.net/user/urn'])
      OMF::Web::SessionStore[:urn, :user] = urn.gsub '|', '+'
    end

    OMF::Web::SessionStore[:id, :irods_user] = user['http://geni.net/irods/username']
    OMF::Web::SessionStore[:id, :irods_zone] = user['http://geni.net/irods/zone']

    OMF::Web::SessionStore[:projects, :geni_portal] = []
    # GENI returns both projects and slices as STRINGs where data somehow referenced to each other
    if (geni_projects = user['http://geni.net/projects']) && (geni_slices = user['http://geni.net/slices'])
      projects = geni_projects.map do |p|
        uuid, name = *(p.split('|'))
        { uuid: uuid, name: name, slices: []}
      end

      geni_slices.each do |s|
        uuid, project_uuid, name = *s.split('|')
        if (p = projects.find { |v| v[:uuid] == project_uuid })
          p[:slices] << { uuid: uuid, name: name }
        end
      end
      # After all that it constructs slices as part of project. Sigh...
      OMF::Web::SessionStore[:projects, :geni_portal] = projects
    end
  end

  def update_geni_projects_slices(user)
    # We can create a default experiment for each project
    if @opts[:ges]
      OMF::Web::SessionStore[:projects, :geni_portal].each do |p|
        proj = find_or_create("projects", p[:name], { irods_user: OMF::Web::SessionStore[:id, :irods_user] })
      end
    end
  end

  def find_or_create(res_path, res_id, additional_data = {})
    ges_url = @opts[:ges]
    obj = HTTParty.get("#{ges_url}/#{res_path}/#{res_id}")

    if obj['uuid'].nil?
      debug "Create a new #{res_path}"
      obj = HTTParty.post("#{ges_url}/#{res_path}", body: { name: res_id }.merge(additional_data))
    else
      debug "Found existing #{res_path} #{obj['name']}"
      # FIXME this hack appends irods user to projects
      if res_path =~ /projects/
        users = obj['irods_user'].split('|')
        current_irods_user = OMF::Web::SessionStore[:id, :irods_user]
        unless users.include? current_irods_user
          new_irods_user = "#{obj['irods_user']}|#{current_irods_user}"
          info "Need to write this #{new_irods_user}"
          HTTParty.post("#{ges_url}/#{res_path}/#{res_id}", body: { irods_user: new_irods_user })
        end
      end
    end

    obj
  end
end

