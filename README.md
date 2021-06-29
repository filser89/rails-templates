# Rails API Template for WeChat (WeiXin) MiniProgram

##Gems Setup:

- Authentication with **devise**
- Authentication with **jwt**
- Background jobs with **sidekiq**
- API calls with **rest-client**
- Handle money and currencies with **money-rails**. Default currency: **_CNY_**
- Model translations with **json_translate**. Locales: :en, :cn
- Active Storage with **activestorage-aliyun**

### Generate your app with the following command:

```bash
rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/filser89/rails-templates/master/rails-wxmp-setup.rb \
  CHANGE_THIS_TO_YOUR_APP_NAME
```
