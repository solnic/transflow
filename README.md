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
- each operation can broadcast its result
- external message consumers can listen to a transaction object for specific events

## Why?

The rationale for this project is quite simple - every use-case in an application
can be described as a series of processing steps where some input is turned into
an output. Steps can result in triggering additional operations handled by other
parts of your application or completely external systems and that can be easily
handled by a pub/sub interface.

It's a clean and simple way of encapsulating complex business logic in your application
using simple, stateless objects.

## Synopsis

Using Transflow is ridiculously simple as it doesn't make much assumptions about
your code. You provide container with operations and they simply need to respond
to `#call(input)` and return output or raise an error if something went wrong.

### Defining a simple flow

``` ruby
DB = []

container = {
  validate: -> input { input[:name].nil? ? raise(Transflow::StepError.new("name nil")) : input  },
  persist: -> input { DB << input[:name] }
}

my_business_flow = Transflow(container: container) { steps :validate, :persist }

my_business_flow[{ name: 'Jane' }]

puts DB.inspect
# ["Jane"]
```

## Defining a flow with event publishers

In many cases an individual operation may require additional behavior to be
triggered. This can be easily achieved with a pub/sub mechanism. Transflow
provides that mechanism through the wonderful `wisper` gem which is used under
the hood.

``` ruby
DB = []

NOTIFICATIONS = [] # just for the sake of the example

class UserPersistListener
  def self.persist_success(user)
    NOTIFICATIONS << "#{user} persisted"
  end

  def self.persist_failure(user, err)
    # do sth about that
  end
end

my_business_flow = Transflow(container: container) do
  step(:validate) { step(:persist, publish: true) }
end

my_business_flow.subscribe(persist: UserPersistListener)

my_business_flow[{ name: 'Jane' }]

puts DB.inspect
# ["Jane"]

puts NOTIFICATIONS.inspect
# ["Jane persisted"]
```

### Passing additional arguments

Another common requirement is to pass aditional arguments that we don't have in
the moment of defining our flow. Fortunately Transflow allows you to pass any
arguments in the moment you call the transaction. Those arguments will be curried
which means you must use either procs as your operation or an object that responds
to `curry`. This limitation will be removed soon.

``` ruby
DB = []

operations = {
  preprocess_input: -> input { { name: input['name'], email: input['email'] } },
  # let's say this one needs additional argument called `email`
  validate_input: -> email, input { input[:email] == email ? input : raise(Transflow::StepError.new('ops')) },
  persist_input: -> input { DB << input[:name] }
}

transflow = Transflow(container: operations) do
  step :preprocess, with: :preprocess_input do
    step :validate, with: :validate_input do
      step :persist, with: :persist_input
    end
  end
end

input = { 'name' => 'Jane', 'email' => 'jane@doe.org' }

# here we say "for `validate` operation curry this additional argument
transflow[input, validate: 'jane@doe.org']

puts DB.inspect
# ["Jane"]
```

### Kleisli Integration

You can use monads from [kleisli](https://github.com/txus/kleisli) gem in your
steps to achieve a nice control-flow without exceptions:

``` ruby

DB = []

validate = -> input do
  if input[:email]
    Right(input)
  else
    Left("what about the email?")
  end
end

persist = -> input do
  input.fmap do |values|
    DB << values
  end
end

container = { validate: validate, persist: persist }

transflow = Transflow(container: container) do
  monadic true

  steps :validate, :persist
end

transflow[name: 'Jane', email: 'jane@doe.org']
# Right([{:name=>"Jane", :email=>"jane@doe.org"}])

transflow[name: 'Jane']
# Left("what about the email?")
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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/solnic/transflow.
