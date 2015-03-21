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
    if (urn = user['http://geni.net/user/urn'].try(:first))
      OMF::Web::SessionStore[:urn, :user] = urn.gsub '|', '+'
    end

    OMF::Web::SessionStore[:username, :irods] = user['http://geni.net/irods/username'].try(:first)
    OMF::Web::SessionStore[:zone, :irods] = user['http://geni.net/irods/zone'].try(:first)

    OMF::Web::SessionStore[:projects, :user] = []
    # GENI returns both projects and slices as STRINGs where data somehow referenced to each other
    if (geni_projects = user['http://geni.net/projects'])
      projects = geni_projects.map do |p|
        puts p
        uuid, name = *(p.split('|'))
        name ||= uuid
        # TODO: GENI HACK!!!!
        urn = "urn:publicid:IDN+ch.geni.net+project+#{name}"
        { uuid: uuid, name: name, urn: urn }
      end

      # After all that it constructs slices as part of project. Sigh...
      OMF::Web::SessionStore[:projects, :user] = projects

      OMF::Web::SessionStore[:current_project, :user] ||= projects.first[:uuid] unless projects.empty?
    end

    # This will fetch slices via geni portal openid instead of slice service
    if @opts[:fetch_slices_from_geni_portal] == true
      OMF::Web::SessionStore[:slices, :user] ||= []
      if (geni_slices = user['http://geni.net/slices'])
        geni_slices.each do |s|
          uuid, project_uuid, name = *(s.split('|'))
          # FIXME Divya indicates the value of slice select during exp setup shall be its name
          # This fetch slices from geni thing should go when they start to use slice_service
          OMF::Web::SessionStore[:slices, :user] << { "name" => name, "slice_urn" => name }
        end

        OMF::Web::SessionStore[:slices, :user].sort! { |v| v["name"] }
      end
    end
  end
end
