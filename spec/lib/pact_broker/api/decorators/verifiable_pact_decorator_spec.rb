require "pact_broker/api/decorators/verifiable_pact_decorator"

module PactBroker
  module Api
    module Decorators
      describe VerifiablePactDecorator do
        before do
          allow_any_instance_of(PactBroker::Api::PactBrokerUrls).to receive(:pact_version_url_with_metadata).and_return("http://pact")
          allow(PactBroker::Pacts::BuildVerifiablePactNotices).to receive(:call).and_return(notices)
          allow_any_instance_of(PactBroker::Pacts::VerifiablePactMessages).to receive(:pact_version_short_description).and_return("short desc")
          allow_any_instance_of(VerifiablePactDecorator).to receive(:build_metadata_for_pact_for_verification).and_return(metadata)
        end

        let(:pending_reason) { "the pending reason" }
        let(:notices) do
          [
            {
              some: "notice"
            }
          ]
        end
        let(:expected_hash) do
          {
            "shortDescription" => "short desc",
            "verificationProperties" => {
              "pending" => true,
              "notices" => [
                {
                  "some" => "notice"
                }
              ]
            },
            "_links" => {
              "self" => {
                "href" => "http://pact",
                "name" => "name"
              }
            }
          }
        end
        let(:decorator) { VerifiablePactDecorator.new(pact) }
        let(:pact) do
          double("PactBroker::Pacts::VerifiablePact",
            pending: true,
            wip: wip,
            name: "name",
            provider_name: "Bar",
            pending_provider_tags: pending_provider_tags,
            consumer_tags: consumer_tags,
            selectors: PactBroker::Pacts::Selectors.new([PactBroker::Pacts::ResolvedSelector.new({ latest: true }, double("version", number: "2", id: 1))]))
        end
        let(:pending_provider_tags) { %w[dev] }
        let(:consumer_tags) { %w[dev] }
        let(:options) { { user_options: { base_url: "http://example.org", include_pending_status: include_pending_status } } }
        let(:include_pending_status) { true }
        let(:wip){ false }
        let(:metadata) { double("metadata") }
        let(:json) { decorator.to_json(options) }

        subject { JSON.parse(json) }

        it "generates a matching hash" do
          expect(subject).to match_pact(expected_hash)
        end

        it "creates the pact version url" do
          expect(decorator).to receive(:pact_version_url_with_metadata).with(pact, metadata, "http://example.org")
          subject
        end

        it "creates the notices" do
          allow(PactBroker::Pacts::BuildVerifiablePactNotices).to receive(:call).with(pact, "http://pact", include_pending_status: include_pending_status)
          subject
        end

        context "when include_pending_status is false" do
          let(:include_pending_status) { false }

          it "does not include the pending flag" do
            expect(subject["verificationProperties"]).to_not have_key("pending")
          end
        end

        context "when wip is true" do
          let(:wip) { true }

          it "includes the wip flag" do
            expect(subject["verificationProperties"]["wip"]).to be true
          end
        end
      end
    end
  end
end
