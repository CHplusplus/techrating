class Person < ApplicationRecord
    has_one_attached :image, dependent: :purge
    before_save :generate_slug
    has_many :votes
    has_many :votations, through: :votes
    has_many :businesses, through: :votations
    has_many :responses
    has_many :questions, through: :responses      

    def full_name
        "#{first_name} #{last_name}"
    end

    def to_param
        slug
    end

    def self.ransackable_attributes(auth_object = nil)
        ["canton", "created_at", "date_of_birth", "first_name", "group", "id", "last_name", "office", "party", "points", "slug", "reputation", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["businesses", "image_attachment", "image_blob", "questions", "responses", "votations", "votes"]
      end

    def calculate_points!

        # Enough votes for a rating?
        if (self.office == "NR" && self.votes.count < 15) or (self.office == "SR" && self.votes.count < 5)
            self.points = 0
            save
            return
        end

        # VOTES
        total_vote_points = 0
        total_possible_vote_points = 0
        # Iterate over all votes of the person.
        self.votes.each do |vote|
            # We count their votes if they have a position 0, 1, 2, or 4.
            if [0, 1, 2, 4].include?(vote.position)
                # Add the votation's weight to total_possible_vote_points
                total_possible_vote_points += vote.votation.weight

                # If the vote's position is 0 or 1, and it's identical to the ideal position, 
                # they get the full votation's weight as additional points
                if [0, 1].include?(vote.position) && vote.position == vote.votation.idealposition
                    total_vote_points += vote.votation.weight
                # If the vote's position is 2 or 4, they get half the votation's weight as additional points
                elsif [2, 4].include?(vote.position)
                    total_vote_points += vote.votation.weight / 2.0
                end
            end
        end
        if total_possible_vote_points == 0
            votes_percentage_achieved = 0
        else 
            votes_percentage_achieved = (total_vote_points / total_possible_vote_points.to_f) * 100
        end

        #SURVEYS
        survey = Survey.where(title_de:"2023").first
        
        total_survey_points = 0
        # Mapping between response and its corresponding points.
        response_points = {
            "Ja" => 4,
            "Eher Ja" => 3,
            "Keine Antwort" => 2,
            "Eher Nein" => 1,
            "Nein" => 0
        }
        
        total_questions_in_survey = survey.questions.count
        total_possible_survey_points = response_points["Ja"] * total_questions_in_survey  # Maximum possible points based on total questions in the survey
        # Iterate over all questions in the survey.
        survey.questions.each do |question|
            # Find the response of the person for this question.
            response = self.responses.find_by(question: question)
            # If the response exists, get its content, otherwise treat as "Keine Antwort"
            content = response ? response.content : "Keine Antwort"
            # Add the points from the mapping to the total
            total_survey_points += response_points[content]
        end
        # The percentage achieved
        survey_percentage_achieved = (total_survey_points / total_possible_survey_points.to_f) * 100
  
        # FINAL POINTS
        # votes count 2/3, survey counts 1/3
        self.points = ((2 * votes_percentage_achieved) + (1 * survey_percentage_achieved)) / 3
        
        # REPUTATION BOOST
        if self.reputation.present?
            self.points += (self.reputation * 5)
        end
        if self.points > 100
            self.points = 100 # can never go beyond 100
        end

        save
      end

    private

    def generate_slug
        self.slug = "#{first_name.parameterize}-#{last_name.parameterize}-#{canton}"
    end

end
