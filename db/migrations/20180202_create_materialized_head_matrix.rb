Sequel.migration do
  up do
    create_table(:materialized_head_matrix, charset: "utf8") do
      Integer :consumer_id, null: false
      String :consumer_name, null: false
      Integer :consumer_version_id, null: false
      String :consumer_version_number, null: false
      Integer :consumer_version_order, null: false
      Integer :pact_publication_id, null: false
      Integer :pact_version_id, null: false
      String :pact_version_sha, null: false
      Integer :pact_revision_number, null: false
      DateTime :pact_created_at, null: false
      Integer :provider_id, null: false
      String :provider_name, null: false
      Integer :provider_version_id
      String :provider_version_number
      Integer :provider_version_order
      Integer :verification_id
      Boolean :success
      Integer :verification_number
      DateTime :verification_executed_at
      String :verification_build_url
      String :consumer_tag_name
      index [:consumer_id], name: "ndx_mhm_consumer_id"
      index [:provider_id], name: "ndx_mhm_provider_id"
      index [:consumer_version_order], name: "ndx_mhm_cv_ord"
    end
  end

  down do
    drop_table(:materialized_head_matrix)
  end
end
