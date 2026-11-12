module Teams
  class TransferOwnershipService
    def self.call(team:, current_owner:, new_owner:)
      new(
        team:,
        current_owner:,
        new_owner:
      ).call
    end

    def initialize(team:, current_owner:, new_owner:)
      @team = team
      @current_owner = current_owner
      @new_owner = new_owner
    end

    def call
      @team.with_lock do
        load_memberships!
        validate_memberships!
        transfer_ownership!
      end
    end

    private

    def load_memberships!
      @current_owner = @team.team_memberships.lock.find(@current_owner.id)
      @new_owner = @team.team_memberships.lock.find(@new_owner.id)
    end

    def validate_memberships!
      validate_current_owner!
      validate_new_owner!
    end

    def validate_current_owner!
      return if @current_owner.status == "active" &&
                @current_owner.role == "owner"

      @current_owner.errors.add(:base, "現在のOwnerではありません")
      raise ActiveRecord::RecordInvalid, @current_owner
    end

    def validate_new_owner!
      if @current_owner.id == @new_owner.id
        @new_owner.errors.add(:base, "移譲元と移譲先は別のメンバーにしてください")
        raise ActiveRecord::RecordInvalid, @new_owner
      end

      return if @new_owner.status == "active" &&
                @new_owner.role == "member"

      @new_owner.errors.add(:base, "移譲先は同じチームのactiveなMemberにしてください")
      raise ActiveRecord::RecordInvalid, @new_owner
    end

    def transfer_ownership!
      demote_current_owner!
      promote_new_owner!
    end

    def demote_current_owner!
      @current_owner.update!(role: "member")
    end

    def promote_new_owner!
      @new_owner.update!(role: "owner")
    end
  end
end
