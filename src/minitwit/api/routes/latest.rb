require 'sinatra'
class MiniTwit < Sinatra::Base

  get '/latest' do
    content_type :json

    # Build the absolute path to the file in the same directory as this file
    file_path = File.join(File.dirname(__FILE__), 'latest_processed_sim_action_id.txt')

    # Set a default value in case we cannot read a valid number from the file
    latest_processed_command_id = -1

    # Check if the file exists
    if File.exist?(file_path)
      begin
        # Read the file's content and remove any extra spaces or newlines (strip)
        file_content = File.read(file_path).strip
        # Convert the file content to an integer
        latest_processed_command_id = Integer(file_content)
      rescue ArgumentError
        # If the conversion fails (e.g., the content is not a number),
        # we keep the default value (-1)
        latest_processed_command_id = -1
      end
    end

    status 200
    body JSON.generate({ "latest" => latest_processed_command_id })
  end

end
