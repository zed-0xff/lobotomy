module AchievementsHelper
  def achievement_li article
    r = '<li style="white-space:pre">'
    r << article[:created_at].strftime("%Y-%m-%d ")

    title = article[:title]
    if title =~ /^(.+) - (\d+[a-z]{2} place)$/
      title = "%-20s %20s" % [$1,$2]
    end

    r << link_to(title, article)
    r << "</li>"
  end
end
