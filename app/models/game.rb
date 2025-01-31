class Game
    attr_reader :players, :current_starting_player, :rounds, :id, :max_round_number, :current_round, :started

    @@games = {}

    def initialize(players = nil, rounds = {})
      raise ArgumentError, "No players provided" unless players
      raise ArgumentError, "Invalid players" unless players.all? { |p| p.is_a?(String) }

      @id = SecureRandom.uuid
      @@games[@id] = self

      @players = players
      @current_starting_player = players.first
      @max_round_number = 0

      parse_rounds(rounds)

      @strategy = PointCalculationStrategy.new()
    end

    def parse_rounds(rounds)
      return if rounds.nil? || rounds.empty?

      # rounds dict looks like this: {"1,4"=>"trump", "2,5"=>"trump"}
      @rounds = rounds.map.with_index do |(round_str, trump), index|
        round_numbers = round_str.split(",").map(&:to_i)
        starting_player = @players[index % @players.length]
        round = Round.new(self, round_numbers.first, round_numbers.last, trump == "trump", starting_player)
        @current_round = round if index == 0 # set current round to the first round

        [ round_numbers.first, round ]
      end.to_h
      @max_round_number = @rounds.keys.max
    end

    def start
        puts "Game started with id #{@id}"
        @started = true
    end

    def self.find(id)
        @@games[id]
    end

    def ask_for_tricks(player, tricks)
        @current_round.ask_for_tricks(player, tricks)
    end

    def register_tricks(player, tricks)
        @current_round.register_tricks(player, tricks)
    end

    def calculate_points(asked_tricks, tricks_made)
        @strategy.calculate_points(asked_tricks, tricks_made)
    end

    def is_current_round(round)
        @current_round.round_number == round.round_number
    end

    def next_round
        next_round_number = @current_round.round_number + 1

        @current_round = @rounds[next_round_number]

        if @current_round.nil?
            @current_round = NullRound.new()
        end
    end

    def next_player_to(player)
        current_index = @players.index(player)
        next_player = @players[(current_index + 1) % @players.length]
        next_player
    end


    def leaderboard
        @total_points = Hash.new(0)
        @rounds.each_value do |round|
            round.points.each do |player, points|
                @total_points[player] += points
            end
        end

        @total_points.sort_by { |player, points| -points }.to_h
    end
end
