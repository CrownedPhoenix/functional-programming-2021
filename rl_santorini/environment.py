from subprocess import check_output
import json


class Env:
    def __init__(self):
        self.reset()
        self.action_space_n = 128

    def get_valid_actions(self, playerId):
        return json.loads(check_output("echo " + self.state + " | ../santorini/santorini -u | ../santorini/santorini -o " + str(playerId), shell=True, encoding='utf8').strip())

    def step(self, actionId):
        new_state = check_output("echo " + self.state + " | ../santorini/santorini -u | ../santorini/santorini -a " +
                                 str(actionId) + " | ../santorini/santorini -v", shell=True, encoding='utf8').strip()

        # Lose if action made no change to board (i.e. action could not be performed)
        if new_state == self.state:
            return self.state, -100, True

        self.state = new_state

        game_status = self.game_status()

        # Check status after my turn
        if game_status['you']:
            return self.state, 0, True
        elif game_status['them']:
            return self.state, -100, True

        self.state = check_output(
            "echo " + self.state + " | ../santorini/santorini -u | ../santorini/santorini -s | ../santorini/santorini -t | ../santorini/santorini -v", shell=True, encoding='utf8').strip()

        game_status = self.game_status()

        # Check status after opponent turn
        if game_status['you']:
            return self.state, 0, True
        elif game_status['them']:
            return self.state, -100, True

        return self.state, -1, False

    def get_starting_state(self):
        return check_output(
            "../santorini/santorini -g | ../santorini/santorini -v", shell=True, encoding='utf8').strip()

    def reset(self):
        self.state = self.get_starting_state()

    def game_status(self):
        my_valid_actions = self.get_valid_actions(0)
        their_valid_actions = self.get_valid_actions(1)
        status = json.loads(check_output(
            "echo " + self.state + " | ../santorini/santorini -u | ../santorini/santorini --state", shell=True, encoding='utf8'))
        status["you"] = status["you"] or len(their_valid_actions) == 0
        status["them"] = status["them"] or len(my_valid_actions) == 0
        return status