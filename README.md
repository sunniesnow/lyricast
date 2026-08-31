# lyricast

Lyrica announcements in Atom format.

## Configuration

You need to provide these values from environment variables:

| Variable | Default (if optional) | Example |
|-|-|-|
| `LYRICAST_PROJECT_ID` | | `72518ac6-9386-43cc-95e0-4a810f4c1de7` |
| `LYRICAST_DATA_DIR` | `data` | `/usr/share/lyricast` |
| `LYRICAST_CONFIG_DIR` | `config` | `/etc/lyricast` |
| `LYRICAST_CACHE_SECONDS` | `600` | `1000` |
| `LYRICAST_INSTANCE_ID` | `http://localhost:4567` | `https://lyricast.example.com` |
| `RACK_ENV` | `development` | `production` |
| `PORT` | `4567` | `80` |

In the directory specified by `LYRICAST_CONFIG_DIR`, there must be the following files:

- `LanguageSheet.asset`
- `SongLibSheet.asset`
- `HeadDataSheet.asset`
- `RoleNameSheet.asset`

## Endpoints

For each of the listed endpoints, you can use `lang` parameter in the query string
to select a language from `tw`, `cn`, `eng`, and `jp`.
The default is `tw`.
For example, to get announcements in simplified Chinese,
use `/announcement.atom?lang=cn`.

- `/announcement.atom`
- `/weekly-mission.atom`
- `/month-ads-song.atom`

## Deployment

On bare metal, with the correct environment variables exported:

```shell
bundle install
bundle exec ./main.rb
```

With Docker Compose:

```yaml
services:
  app:
    image: ulysseszhan/lyricast
    container_name: lyricast
    restart: unless-stopped
    environment:
      LYRICAST_PROJECT_ID: 72518ac6-9386-43cc-95e0-4a810f4c1de7
      LYRICAST_CACHE_SECONDS: '600'
      LYRICAST_INSTANCE_ID: https://lyricast.example.com
    ports:
      - '80:4567'
    volumes:
      - ./data:/data
      - ./config:/config
```

Change `80` to the port on which you want it to be hosted.

## License

AGPL-3.0-or-later.
