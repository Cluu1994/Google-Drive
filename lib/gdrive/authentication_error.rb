# Author: Hiroshi Ichikawa <http://gimite.net/>
# The license of this source is "New BSD Licence"

require "gdrive/error"


module GDrive

    # Raised when GoogleDrive.login has failed.
    class AuthenticationError < GoogleDrive::Error

    end

end
