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
    end
  end
end
