class License < ApplicationRecord
  enum approval_status: {
      approved: "Approved",
      disapproved: "Disapproved",
      pending: "Pending"
  }

  enum purpose: {
      non_profit_research_individual: "Non-Profit Research - Individual",
      non_profit_research_team: "Non-Profit Research - Team",
      non_profit_public_portal: "Host a Public Portal (Research/Non-Profit)",
      education: "Education",
      non_profit_other: "Non-Profit — Other",
      commercial_research: "Commercial - Research",
      commercial_managing_semantic_resources: "Commercial - Managing Semantic Resources",
      commercial_public_portal: "Commercial - Host a Public Portal",
      commercial_other: "Commercial - Other"
  }
end
