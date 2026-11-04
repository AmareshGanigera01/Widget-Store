# Widget Marketplace Backend

FastAPI backend for the Android Widget Marketplace & Overlay Platform.

## Features

- **User Management**: User registration, authentication, and profile management
- **Widget Marketplace**: CRUD operations for widget listings
- **Favorites System**: Users can favorite widget listings
- **Usage Analytics**: Track widget usage and interactions
- **RESTful API**: Fully documented REST endpoints
- **PostgreSQL Database**: Scalable relational database

## Prerequisites

- Python 3.9+
- PostgreSQL 13+
- pip (Python package manager)

## Installation

1. Clone the repository:
```bash
cd backend
```

2. Create a virtual environment:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Copy the environment file:
```bash
cp .env.example .env
```

5. Edit `.env` with your database configuration:
```env
DATABASE_URL=postgresql://username:password@localhost:5432/widget_marketplace
```

6. Set up PostgreSQL database:
```sql
CREATE DATABASE widget_marketplace;
CREATE USER widget_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE widget_marketplace TO widget_user;
```

## Running the Application

### Development
```bash
python run.py
```

The API will be available at `http://localhost:8000`

### Production
```bash
uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4
```

## API Documentation

Once running, visit:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`

## API Endpoints

### Health Check
- `GET /health` - Check API health status

### Users
- `POST /users/` - Create a new user
- `GET /users/{user_id}` - Get user by ID

### Widget Listings
- `GET /listings/` - Get all listings (with pagination)
- `POST /listings/` - Create a new listing
- `GET /listings/{listing_id}` - Get specific listing
- `PUT /listings/{listing_id}` - Update listing
- `DELETE /listings/{listing_id}` - Delete listing

### User Favorites
- `POST /users/{user_id}/favorites/{listing_id}` - Add favorite
- `DELETE /users/{user_id}/favorites/{listing_id}` - Remove favorite
- `GET /users/{user_id}/favorites/` - Get user favorites

## Database Schema

### Users Table
- `id` (Primary Key)
- `email` (Unique)
- `name`
- `hashed_password`
- `is_active`
- `created_at`
- `updated_at`

### Widget Listings Table
- `id` (Primary Key)
- `name`
- `description`
- `category`
- `author`
- `version`
- `price`
- `config_schema` (JSON)
- `preview_image_url`
- `download_count`
- `rating`
- `review_count`
- `is_featured`
- `is_approved`
- `created_at`
- `updated_at`

### User Favorites Table
- `id` (Primary Key)
- `user_id` (Foreign Key)
- `listing_id` (Foreign Key)
- `created_at`

### Installed Widgets Table
- `id` (UUID, Primary Key)
- `user_id` (Foreign Key)
- `listing_id` (Foreign Key)
- `name`
- `config` (JSON)
- `is_enabled`
- `placement`
- `last_used`
- `created_at`
- `updated_at`

### Widget Usage Table
- `id` (Primary Key)
- `widget_id` (Foreign Key)
- `timestamp`
- `event_type`
- `duration_seconds`
- `data` (JSON)

## Testing

Run tests with pytest:
```bash
pytest
```

## Deployment

### Docker
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Cloud Deployment Options
- **Render.com**: Easy deployment with PostgreSQL
- **Railway.app**: Full-stack deployment platform
- **AWS Elastic Beanstalk**: Managed AWS deployment
- **Google Cloud Run**: Serverless container deployment

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection URL | `postgresql://postgres:password@localhost:5432/widget_marketplace` |
| `SECRET_KEY` | JWT secret key | `your-secret-key` |
| `ALGORITHM` | JWT algorithm | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Token expiry time | `30` |
| `ALLOWED_ORIGINS` | CORS allowed origins | `http://localhost:3000,http://localhost:8080` |

## Development Notes

- The database automatically creates tables on first run
- All endpoints return JSON responses
- Error handling includes proper HTTP status codes
- Input validation uses Pydantic schemas
- Password hashing uses bcrypt

## Future Enhancements

1. **Authentication**: JWT-based authentication
2. **File Upload**: Widget preview images
3. **Search**: Full-text search for listings
4. **Recommendations**: AI-powered widget recommendations
5. **Analytics Dashboard**: Usage statistics and insights
6. **WebSocket**: Real-time updates for installed widgets
7. **Rate Limiting**: API rate limiting
8. **Caching**: Redis caching for frequent queries