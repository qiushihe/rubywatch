# RubyWatch

Amazon CloudWatch daemon written in Ruby

### Setup

Create a `config.yml` based on the content of `config.example.yml`.

Make `rubywatch.rb` executable:

    $ chmod +x rubywatch.rb

### Usage

To simply run the script once:

    $ ./rubywatch.rb

To make the script run every minutes, create a file in `/etc/cron.d/` with the content:

    * * * * * root /path/to/rubywatch/rubywatch.rb

... or simply put the above content in `/etc/crontab`. And to make the script run every 5 minutes instead, use:

    */5 * * * * root /path/to/rubywatch/rubywatch.rb
