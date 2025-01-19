
# Real-Time Sports Betting & Leaderboard System (Rails)

## Overview

This repository contains the **Rails** backend service for the sports betting and leaderboard system. The Rails backend handles the core application logic, user data, and database interactions. It also supports authentication and serves as the foundation for the real-time features implemented in the Node.js layer.

## Features

- **Authentication:** JWT-based user authentication.
- **Database:** ActiveRecord models with PostgreSQL.
- **Seed Data:** Preloads essential data for development and testing.
- **RSpec:** Test suite to ensure code quality.
- **Foreman:** Simplified server and worker process management.

---

## Installation

1. **Clone the repository:**
   ```sh
   git clone <repo-url>
   cd rails-service
   ```

2. **Install dependencies:**
   ```sh
   bundle install
   ```

3. **Set up the database:**
   ```sh
   rails db:create
   rails db:migrate
   rails db:seed
   ```
  **If you've previously worked with the repo before the addition of the balance layer for users, please clear out your database first:
   ```sh
  drop database sport_betting_app_development
  drop database sport_betting_test
  rails db:create
  rails db:migrate
  rails db:seed
   ```

   

4. **Run tests:**
   ```sh
   bundle exec rspec


    (rate limiting test run on terminal)
    for i in {1..15}; do curl -X POST -d "email=test@example.com&password=wrongpassword" http://localhost:7000/login; done 

   ```

5. **Start the server:**
   ```sh
   bundle exec foreman start
   ```

- `http://127.0.0.1:7000/api-docs/index.html` – Connect to swagga docs

---

## Contributing

1. Fork the repo.
2. Create a new branch (`feature-xyz`).
3. Commit your changes.
4. Open a Pull Request.

---

# Future Enhancements: Automating Event Results

In a real-world scenario, betting results should be automatically updated. 
This can be done via:
1. **Webhooks**: A sports data provider (e.g., Sportradar) sends real-time event updates.
2. **Scheduled Jobs**: A cron job periodically fetches event results from an API.

For this test, results are manually updated, but in production, we would integrate an external API.


## License

MIT License.
