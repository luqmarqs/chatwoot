json.array! @recipients do |recipient|
  json.id recipient.id
  json.recipient_key recipient.recipient_key
  json.phone_number recipient.phone_number
  json.status recipient.status
  json.provider_message_id recipient.provider_message_id
  json.sent_at recipient.sent_at
  json.delivered_at recipient.delivered_at
  json.read_at recipient.read_at
  json.failed_at recipient.failed_at
  json.failure_code recipient.failure_code
end
