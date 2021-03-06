defmodule CercleApi.APIV2.ActivityViewTest do
  use CercleApi.ConnCase, async: true
  import CercleApi.Factory
  alias CercleApi.APIV2.ActivityView
  use Timex

  test "list.json" do
    user = insert(:user)
    company = insert(:company)
    activity = insert(:activity,
      user: user, company: company, due_date: Timex.now()
    )
    rendered_activities = ActivityView.render("list.json",
      %{
        activities: [activity]
      })

    assert rendered_activities == %{
      activities: [ActivityView.activity_json(activity)]
    }
  end
end
