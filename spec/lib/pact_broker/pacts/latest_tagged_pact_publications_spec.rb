require "pact_broker/pacts/latest_tagged_pact_publications"

module PactBroker
  module Pacts
    describe LatestTaggedPactPublications do
      subject { LatestTaggedPactPublications.for_selector(selector).order(:consumer_name, :consumer_version_order) }

      context "for latest for a specified tag" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "3", "Bar")
            .create_consumer_version_tag("prod")
        end

        let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "dev", latest: true) }

        it "returns matching rows" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for latest for a specified tag and consumer" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo2", "3", "Bar")
            .create_consumer_version_tag("dev")
        end

        let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "dev", latest: true, pacticipant_name: "Foo") }

        it "returns matching rows" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for all for a specified tag" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "3", "Bar")
            .create_consumer_version_tag("prod")
        end

        let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: "dev") }

        it "returns matching rows (which are only the latest)" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for latest for any tag" do
        before do
          td.create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
            .create_pact_with_hierarchy("Foo", "3", "Bar")
            .create_consumer_version_tag("prod")
        end

        let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, latest: true) }

        it "returns matching rows" do
          expect(subject.count).to eq 2
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end

      context "for latest for any tag with a max age" do
        before do
          td.subtract_days(7)
            .create_pact_with_hierarchy("Foo", "1", "Bar")
            .create_consumer_version_tag("prod")
            .add_days(4)
            .create_pact_with_hierarchy("Foo", "2", "Bar")
            .create_consumer_version_tag("dev")
        end

        let(:selector) { PactBroker::Matrix::UnresolvedSelector.new(tag: true, latest: true, max_age: 5) }

        it "returns matching rows" do
          expect(subject.count).to eq 1
          expect(subject.first.consumer_version_number).to eq "2"
        end
      end
    end
  end
end
