# FastAPI Backend Integration Test Plan

## Setup Instructions

### 1. Start FastAPI Backend
```bash
cd backend
pip install -r requirements.txt
python run.py
```

### 2. Configure Flutter App
Update the main.dart file or use environment variables to enable API backend:

**Option A: Update main.dart directly**
```dart
const useApiBackend = true; // Change from false to true
```

**Option B: Use environment variables (recommended)**
```bash
# For development
flutter run --dart-define=USE_API_BACKEND=true

# For build
flutter build apk --dart-define=USE_API_BACKEND=true
```

### 3. Database Setup
Ensure PostgreSQL is running and create the database:
```sql
CREATE DATABASE widget_marketplace;
```

Update the `.env` file in the backend directory with your database credentials.

## Test Scenarios

### Scenario 1: API Health Check
- Start FastAPI backend
- Run Flutter app with API backend enabled
- Verify app loads without errors
- Check console logs for API connection status

### Scenario 2: List Marketplace Listings
- Ensure backend has sample data
- Navigate to marketplace screen
- Verify listings load from API
- Check that fallback to local data works if API is unavailable

### Scenario 3: Download/Install Widget
- Select a widget from marketplace
- Click "Install" or "Download"
- Verify download count increments in API
- Check widget appears in "My Widgets"

### Scenario 4: Publish Widget
- Create a widget in "My Widgets"
- Publish it to marketplace
- Verify widget appears in API listings
- Check that other users can see it

### Scenario 5: Favorites System
- Mark a listing as favorite
- Verify favorite is recorded in API
- Check favorites list loads from API

## Expected Behavior

### When API is Available:
1. Marketplace listings load from FastAPI backend
2. Download counts update via API
3. Published widgets are stored in PostgreSQL
4. Favorites are synced with backend
5. User data (for future auth) is managed by API

### When API is Unavailable:
1. App falls back to local SQLite data
2. Download counts are stored locally
3. Published widgets are stored locally
4. User can still use core functionality
5. App attempts to sync when API becomes available

## Troubleshooting

### Common Issues:

1. **API Connection Failed**
   - Check if FastAPI backend is running
   - Verify `API_BASE_URL` in `api_config.dart`
   - Check network connectivity

2. **Database Errors**
   - Verify PostgreSQL is running
   - Check database credentials in `.env`
   - Ensure tables are created (they auto-create on first run)

3. **CORS Errors**
   - Update CORS settings in FastAPI app
   - Check `ALLOWED_ORIGINS` in backend configuration

4. **Data Conversion Errors**
   - Verify API response format matches expected schema
   - Check `fromApiData` method in `marketplace_listing.dart`

### Debug Logs:
Check Flutter console for:
- API connection attempts
- Response status codes
- Data parsing errors
- Fallback activation messages

## Performance Considerations

1. **Network Latency**: API calls add network latency
2. **Offline Support**: App works offline with local fallback
3. **Data Sync**: Consider periodic sync for better UX
4. **Caching**: Implement caching for frequently accessed data

## Next Steps

1. **Authentication**: Add JWT authentication to API
2. **File Upload**: Support widget preview images
3. **Real-time Updates**: Add WebSocket for live updates
4. **Analytics Dashboard**: Usage statistics from API data
5. **Search**: Implement full-text search in API
6. **Recommendations**: AI-powered widget suggestions