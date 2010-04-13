require 'spec/spec_helper'

describe Flock::MockService do
  describe 'Class Methods' do


    describe 'inspect'
    describe 'execute'
    describe 'select'
    describe 'count'
    describe 'counts_of_sources_for'

    # private methods
    describe 'select_query'
    describe 'graphs'
    describe 'iterate'
    describe 'empty_result'
    describe 'sources'
    describe 'destinations'
    describe 'archived_sources'
    describe 'archived_destinations'

    # deprecated public methods
    describe 'offset_sources_for'
    describe 'offset_destinations_for'
  end
end
