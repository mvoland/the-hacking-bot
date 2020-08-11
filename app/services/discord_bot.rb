class DiscordBot
  @@discord_bot = nil

  def self.run
    return false unless @@discord_bot.nil?

    @@discord_bot = Discordrb::Commands::CommandBot.new token: ENV['DISCORD_BOT_TOKEN'],
                                                        client_id: ENV['DISCORD_CLIENT_ID'],
                                                        prefix: '$',
                                                        advanced_functionality: true
    bot = @@discord_bot

    bot.command :verify do |event, email, token|
      # Can't find user
      unless (user = User.find_by(email: email))
        event.respond "Pas d'utilisateur avec cet email : #{email}"
        event.respond 'Merci de recommencer : <https://the-hacking-bot.herokuapp.com/discord_verify>'
        return
      end

      # Account already linked
      if user.discord?
        event.respond 'Ton compte est déjà lié : <https://the-hacking-bot.herokuapp.com/profile>'
        return
      end

      # Token is not right
      unless BCrypt::Password.new(user.discord_verify_digest).is_password?(token)
        event.respond 'Le token ne semble pas valide'
        event.respond 'Merci de recommencer : <https://the-hacking-bot.herokuapp.com/discord_verify>'
        return
      end

      # Update user does not work
      unless user.update(discord_id: event.user.id, discord_username: event.user.username)
        event.respond 'Désolé, il y a eu un problème inconnu (êtes vous déjà inscrit avec le même Discord ID ?)'
        event.respond user.errors.full_messages.map(&:to_s).join "\n"
        return
     end

      # OK, thank user
      event.respond "Merci #{event.user.username}, tu as bien lié ton compte <https://the-hacking-bot.herokuapp.com/profile>"
      # user.work_in_progress!
    end

    #     bot.command :sign_out do |event|
    #       user = User.find_by(discord_id: event.user.id)
    #       if user
    #         if user.destroy
    #           event.respond "Désolé de te voir partir #{event.user.username}"
    #         else
    #           event.respond 'Il y a eu un problème avec la désinscription, merci de nous faire un retour'
    #         end
    #       else
    #         event.respond "Utilisateur #{event.user.username} non trouvé, est-tu bien inscrit avec '$sign_up' ?"
    #       end
    #       event.respond "Plus d'information sur <https://the-hacking-bot.herokuapp.com>"
    #     end

    #     bot.command :need_help do |event|
    #       user = User.find_by(discord_id: event.user.id)
    #       if user
    #         user.need_help!
    #         event.respond "OK #{user.name}"
    #       else
    #         event.respond "Utilisateur #{event.user.username} non trouvé, est-tu bien inscrit avec '$sign_up' ?"
    #       end
    #       event.respond "Plus d'information sur <https://the-hacking-bot.herokuapp.com>"
    #     end

    #     bot.command :can_help do |event|
    #       user = User.find_by(discord_id: event.user.id)
    #       if user
    #         user.can_help!
    #         event.respond "OK #{user.name}"
    #       else
    #         event.respond "Utilisateur #{event.user.username} non trouvé, est-tu bien inscrit avec '$sign_up' ?"
    #       end
    #       event.respond "Plus d'information sur <https://the-hacking-bot.herokuapp.com>"
    #     end

    #     bot.command :work_in_progress do |event|
    #       user = User.find_by(discord_id: event.user.id)
    #       if user
    #         user.work_in_progress!
    #         event.respond "OK #{user.name}"
    #       else
    #         event.respond "Utilisateur #{event.user.username} non trouvé, est-tu bien inscrit avec '$sign_up' ?"
    #       end
    #       event.respond "Plus d'information sur <https://the-hacking-bot.herokuapp.com>"
    #     end

    #     bot.command :help do |event|
    #       event.respond "Liste des commandes (The Hacking Bot):
    # ------------------------------------------------------------------------
    # `$help . . . . . . .` > ce message
    # `$sign_up  . . . . .` > je veux m'inscrire
    # `$sign_out . . . . .` > je veux me désinscrire
    # `$can_help . . . . .` > modifier mon statut, je peux aider quelqu'un
    # `$need_help  . . . .` > modifier mon statut, j'ai besoin d'aide
    # `$work_in_progress .` > modifier mon statut, je ne veux pas être dérangé"
    #       event.respond "Plus d'information sur <https://the-hacking-bot.herokuapp.com>"
    #     end

    at_exit { bot.stop }
    bot.run :async
    true
  end
end