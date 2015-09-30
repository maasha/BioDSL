# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# Copyright (C) 2007-2015 Martin Asser Hansen (mail@maasha.dk).                #
#                                                                              #
# This program is free software; you can redistribute it and/or                #
# modify it under the terms of the GNU General Public License                  #
# as published by the Free Software Foundation; either version 2               #
# of the License, or (at your option) any later version.                       #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program; if not, write to the Free Software                  #
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301,    #
# USA.                                                                         #
#                                                                              #
# http://www.gnu.org/copyleft/gpl.html                                         #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #
#                                                                              #
# This software is part of Biopieces (www.biopieces.org).                      #
#                                                                              #
# >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< #

module BioPieces
  # Namespace for EmailHelper.
  module EmailHelper
    # Send email notification to email address specfied in @options[:email],
    # including a optional subject specified in @options[:subject], that will
    # otherwise default to self.to_s. The body of the email will be an HTML
    # report.
    #
    # @param pipeline [BioPieces::Pipeline] Pipeline object
    def send_email(pipeline)
      return unless @options[:email]

      html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body BioPieces::HtmlReport.new(pipeline).to_html
      end

      compose_mail(html_part).deliver!
    end

    # Compose an email.
    #
    # @param html_part [Mail::Part] The email body.
    #
    # @return [Mail] Mail to be sent.
    def compose_mail(html_part)
      mail = Mail.new
      mail[:from]    = "do-not-reply@#{`hostname -f`.strip}"
      mail[:to]      = @options[:email]
      mail[:subject] = @options[:subject] || to_s.first(30)
      mail.html_part = html_part
      mail.delivery_method :smtp,
                           address: 'localhost',
                           port: 25,
                           enable_starttls_auto: false
      mail
    end
  end
end
