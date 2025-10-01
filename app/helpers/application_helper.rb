# frozen_string_literal: true

module ApplicationHelper
  def get_alert_class(flash_type)
    alert_class_mapping = {
      notice: "alert-success",
      alert: "alert-danger"
    }
    "container alert #{alert_class_mapping[flash_type.to_sym]} alert-dismissible fade show"
  end
end
