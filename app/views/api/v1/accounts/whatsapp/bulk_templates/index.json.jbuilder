json.payload do
  json.array! @templates do |template|
    json.id                    template.id
    json.name                  template.name
    json.language              template.language
    json.category              template.category
    json.status                template.status
    json.provider_template_id  template.provider_template_id
    json.provider_template_name template.provider_template_name
    json.provider_template_namespace template.provider_template_namespace
    json.header_text           template.header_text
    json.body_text             template.body_text
    json.footer_text           template.footer_text
    json.button_labels         template.button_labels
    json.content_snapshot      template.content_snapshot
    json.approved_at           template.approved_at
    json.last_synced_at        template.last_synced_at
    json.created_at            template.created_at
    json.updated_at            template.updated_at
  end
end
