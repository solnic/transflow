[gem]: https://rubygems.org/gems/transflow
[travis]: https://travis-ci.org/solnic/transflow
[gemnasium]: https://gemnasium.com/solnic/transflow
[codeclimate]: https://codeclimate.com/github/solnic/transflow
[inchpages]: http://inch-ci.org/github/solnic/transflow

# Transflow

[![Gem Version](https://badge.fury.io/rb/transflow.svg)][gem]
[![Build Status](https://travis-ci.org/solnic/transflow.svg?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/solnic/transflow.png)][gemnasium]
[![Code Climate](https://codeclimate.com/github/solnic/transflow/badges/gpa.svg)][codeclimate]
[![Test Coverage](https://codeclimate.com/github/solnic/transflow/badges/coverage.svg)][codeclimate]
[![Inline docs](http://inch-ci.org/github/solnic/transflow.svg?branch=master)][inchpages]

Business transaction flow DSL. The aim of this small gem is to provide a simple
way of defining complex business transaction flows that include processing by
many different objects.

It is based on the following ideas:

- a business transaction is a series of operations where each can fail and stop processing
- a business transaction resolves its dependencies using an external container object
  and it doesn't know any details about the individual operation objects except their
  identifiers
- a business transaction can describe the flow on an abstract level without being
  coupled to any details about how individual operations work
- a business transaction doesn't have any state
- each operation shouldn't accumulate state, instead it should receive an input and return
  an output without causing any side-effects
- the only interface of a an operation is `#call(input)`
- each operation provides a meaningful functionality and can be reused
- each operation can broadcast its result (TODO)
- external message consumers can listen to a transaction object for specific events (TODO)

## Why?

The rationale for this project is quite simple - every use-case in an application
can be described as a series of processing steps where some input is turned into
an output. Steps can result in triggering additional operations handled by other
parts of your application or completely external systems and that can be easily
handled by a pub/sub interface.

It's a clean and simple way of encapsulating complex business logic in your application
using simple, stateless objects.

## Error Handling

This will be the tricky part - there are scenarios where we need to aggregate
errors from multiple steps without stopping the processing. It's not implemented
yet but *probably* using pub/sub for that will do the work as we can register an
error listener that can simply gather errors and return it as a result.

## Synopsis

``` ruby
DB = []

container = {
  validate: -> input { raise "name nil" if input[:name].nil? },
  persist: -> input { DB << input[:name] }
}

my_business_flow = Transflow(container: container) do
  step(:validate) { step(:persist) }
end

my_business_flow[{ name: 'Jane' }]

puts DB.inspect
# ["Jane"]

## The same but with events

NOTIFICATIONS = []

class Notify
  def persist_success(user)
    NOTIFICATIONS << "#{user} persisted"
  end

  def persist_failure(user, err)
    # do sth about that
  end
end

my_business_flow = Transflow(container: container) do
  step(:validate) { step(:persist, publish: true) }
end

notify = Notify.new

my_business_flow.subscribe(persist: notify)

my_business_flow[{ name: 'Jane' }]

puts DB.inspect
# ["Jane"]

puts NOTIFICATIONS.inspect
# ["Jane persisted"]
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'transflow'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install transflow

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/transflow.
