# Read the file with Twitter API information
TOKENS = YAML::load_file File.join(Rails.root, 'config', 'twitter.yml')