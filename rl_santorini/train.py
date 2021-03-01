import numpy as np
import matplotlib.pyplot as plt
import environment as env

env = env.Env()

LEARNING_RATE = 0.1

DISCOUNT = 0.95
EPISODES = 20000
STATS_EVERY = 10

# Exploration settings
epsilon = 1  # not a constant, going to be decayed
START_EPSILON_DECAYING = 1
END_EPSILON_DECAYING = EPISODES//2
epsilon_decay_value = epsilon/(END_EPSILON_DECAYING - START_EPSILON_DECAYING)

# For stats
ep_rewards = []
aggr_ep_rewards = {'ep': [], 'avg': [], 'max': [], 'min': []}


q_table = np.load("./qtables/1/800-qtable.npy", allow_pickle=True).item()
for episode in range(EPISODES):
    state = env.reset()

    if state not in q_table:
        q_table[state] = np.random.uniform(
            low=-2, high=0, size=env.action_space_n)

    episode_reward = 0
    done = False

    while not done:
        valid_actions = env.get_valid_actions(0)

        action = max(valid_actions, key=lambda a: q_table[state][a])
        new_state, reward, done = env.step(action)
        episode_reward += reward

        if new_state not in q_table:
            q_table[new_state] = np.random.uniform(
                low=-2, high=0, size=env.action_space_n)

        print(reward, new_state, action)

        # If simulation did not end yet after last step - update Q table
        if not done:

            # Maximum possible Q value in next step (for new state)
            max_future_q = np.max(q_table[new_state])

            # Current Q value (for current state and performed action)
            current_q = q_table[state][action]

            # And here's our equation for a new Q value for current state and action
            new_q = (1 - LEARNING_RATE) * current_q + LEARNING_RATE * \
                (reward + DISCOUNT * max_future_q)

            # Update Q table with new Q value
            q_table[state][action] = new_q

        # Simulation ended (for any reson) - if goal position is achived - update Q value with reward directly
        else:
            game_status = env.game_status()
            if game_status['you']:
                q_table[state][action] = reward
            elif game_status['them']:
                q_table[state][action] = -100

        state = new_state

    if episode % 100 == 0:
        np.save(f"qtables/2/{episode}-qtable.npy", q_table)

    # Decaying is being done every episode if episode number is within decaying range
    if END_EPSILON_DECAYING >= episode >= START_EPSILON_DECAYING:
        epsilon -= epsilon_decay_value

    ep_rewards.append(episode_reward)
    if not episode % STATS_EVERY:
        average_reward = sum(ep_rewards[-STATS_EVERY:])/STATS_EVERY
        aggr_ep_rewards['ep'].append(episode)
        aggr_ep_rewards['avg'].append(average_reward)
        aggr_ep_rewards['max'].append(max(ep_rewards[-STATS_EVERY:]))
        aggr_ep_rewards['min'].append(min(ep_rewards[-STATS_EVERY:]))
        print(
            f'Episode: {episode:>5d}, average reward: {average_reward:>4.1f}, current epsilon: {epsilon:>1.2f}')
plt.plot(aggr_ep_rewards['ep'],
         aggr_ep_rewards['avg'], label="average rewards")
plt.plot(aggr_ep_rewards['ep'], aggr_ep_rewards['max'], label="max rewards")
plt.plot(aggr_ep_rewards['ep'], aggr_ep_rewards['min'], label="min rewards")
plt.legend(loc=4)
plt.show()
