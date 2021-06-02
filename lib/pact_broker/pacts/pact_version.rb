require "sequel"
require "pact_broker/repositories/helpers"
require "pact_broker/verifications/latest_verification_for_pact_version"

module PactBroker
  module Pacts
    class PactVersion < Sequel::Model(:pact_versions)
      plugin :timestamps
      plugin :upsert, identifying_columns: [:consumer_id, :provider_id, :sha]

      one_to_many :pact_publications, reciprocal: :pact_version
      one_to_many :verifications, reciprocal: :verification, order: :id, class: "PactBroker::Domain::Verification"
      one_to_one :latest_verification, class: "PactBroker::Verifications::LatestVerificationForPactVersion", key: :pact_version_id, primary_key: :id
      associate(:many_to_one, :provider, class: "PactBroker::Domain::Pacticipant", key: :provider_id, primary_key: :id)
      associate(:many_to_one, :consumer, class: "PactBroker::Domain::Pacticipant", key: :consumer_id, primary_key: :id)

      dataset_module do
        include PactBroker::Repositories::Helpers

        def join_successful_verifications
          verifications_join = {
            Sequel[:verifications][:pact_version_id] => Sequel[:pact_versions][:id],
            Sequel[:verifications][:success] => true
          }
          join(:verifications, verifications_join)
        end

        def join_provider_versions
          join(:versions, { Sequel[:provider_versions][:id] => Sequel[:verifications][:provider_version_id] }, { table_alias: :provider_versions })
        end

        def join_provider_version_tags_for_tag(tag)
          tags_join = {
            Sequel[:tags][:version_id] => Sequel[:provider_versions][:id],
            Sequel[:tags][:name] => tag
          }
          join(:tags, tags_join)
        end
      end

      def name
        "Pact between #{consumer_name} and #{provider_name}"
      end

      def provider_name
        pact_publications.last.provider.name
      end

      def consumer_name
        pact_publications.last.consumer.name
      end

      def latest_consumer_version
        consumer_versions.last
      end

      def latest_pact_publication
        PactBroker::Pacts::LatestPactPublicationsByConsumerVersion
          .where(pact_version_id: id)
          .order(:consumer_version_order)
          .last || PactBroker::Pacts::AllPactPublications
          .where(pact_version_id: id)
          .order(:consumer_version_order)
          .last
      end

      def consumer_versions
        PactBroker::Domain::Version.where(id: PactBroker::Pacts::PactPublication.select(:consumer_version_id).where(pact_version_id: id)).order(:order)
      end

      def latest_consumer_version_number
        latest_consumer_version.number
      end

      def select_provider_tags_with_successful_verifications_from_another_branch_from_before_this_branch_created(tags)
        tags.select do | tag |
          first_tag_with_name = PactBroker::Domain::Tag.where(pacticipant_id: provider_id, name: tag).order(:created_at).first

          verifications_join = {
            Sequel[:verifications][:pact_version_id] => Sequel[:pact_versions][:id],
            Sequel[:verifications][:success] => true
          }
          tags_join = {
            Sequel[:tags][:version_id] => Sequel[:versions][:id],
          }
          query = PactVersion.where(Sequel[:pact_versions][:id] => id)
            .join(:verifications, verifications_join)
            .join(:versions, Sequel[:versions][:id] => Sequel[:verifications][:provider_version_id])
            .join(:tags, tags_join) do
              Sequel.lit("tags.name != ?", tag)
            end

          if first_tag_with_name
            query = query.where { Sequel[:verifications][:created_at] < first_tag_with_name.created_at }
          end

          query.any?
        end
      end

      def select_provider_tags_with_successful_verifications(tags)
        tags.select do | tag |
          PactVersion.where(Sequel[:pact_versions][:id] => id)
            .join_successful_verifications
            .join_provider_versions
            .join_provider_version_tags_for_tag(tag)
            .any?
        end
      end

      def verified_successfully_by_any_provider_version?
        PactVersion.where(Sequel[:pact_versions][:id] => id)
          .join_successful_verifications
          .any?
      end
    end
  end
end

# Table: pact_versions
# Columns:
#  id          | integer                     | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  consumer_id | integer                     | NOT NULL
#  provider_id | integer                     | NOT NULL
#  sha         | text                        | NOT NULL
#  content     | text                        |
#  created_at  | timestamp without time zone | NOT NULL
# Indexes:
#  pact_versions_pkey   | PRIMARY KEY btree (id)
#  unq_pvc_con_prov_sha | UNIQUE btree (consumer_id, provider_id, sha)
# Foreign key constraints:
#  pact_versions_consumer_id_fkey | (consumer_id) REFERENCES pacticipants(id)
#  pact_versions_provider_id_fkey | (provider_id) REFERENCES pacticipants(id)
# Referenced By:
#  pact_publications                                            | pact_publications_pact_version_id_fkey                          | (pact_version_id) REFERENCES pact_versions(id)
#  verifications                                                | verifications_pact_version_id_fkey                              | (pact_version_id) REFERENCES pact_versions(id)
#  latest_pact_publication_ids_for_consumer_versions            | latest_pact_publication_ids_for_consumer_v_pact_version_id_fkey | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
#  latest_verification_id_for_pact_version_and_provider_version | latest_v_id_for_pv_and_pv_pact_version_id_fk                    | (pact_version_id) REFERENCES pact_versions(id) ON DELETE CASCADE
