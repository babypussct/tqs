# Cloudflare R2 media storage

Pha 5 dùng một endpoint server-only để cấp presigned `PUT` URL. Browser không nhận
`R2_ACCESS_KEY_ID` hoặc `R2_SECRET_ACCESS_KEY`; browser chỉ nhận URL tạm thời và
public URL của object sau khi upload.

## Vercel environment variables

Khai báo ở Preview/Production tương ứng:

```text
R2_ACCOUNT_ID=<Cloudflare account id>
R2_ACCESS_KEY_ID=<R2 API token access key>
R2_SECRET_ACCESS_KEY=<R2 API token secret>
R2_BUCKET_NAME=<bucket name>
R2_PUBLIC_BASE_URL=https://media.example.com
MEDIA_ALLOWED_ORIGINS=https://tqs.vn,https://tqsshop.vercel.app,http://localhost:3000
```

`CLOUDFLARE_ACCOUNT_ID` vẫn được hỗ trợ làm fallback cho `R2_ACCOUNT_ID`.
`R2_CUSTOM_DOMAIN` vẫn được hỗ trợ làm fallback cho `R2_PUBLIC_BASE_URL`.
Public URL phải trỏ tới custom domain/R2 public bucket đã được cấu hình để đọc
object; presigned URL chỉ dùng cho thao tác `PUT`.

## Endpoint contract

`POST /api/media/upload-url` yêu cầu Firebase ID token của admin và nhận:

```json
{
  "filename": "cover.png",
  "contentType": "image/png",
  "size": 123456,
  "category": "products"
}
```

Các category và quyền tương ứng:

| Category | Permission |
| --- | --- |
| `products` | `manageProducts` |
| `posts` | `managePosts` hoặc legacy `manageHomepage` |
| `banners` | `manageHomepage` hoặc `manageSettings` |

Super-admin từ `isSuperAdmin === true` hoặc custom claim `super_admin === true`
được phép trên mọi category. Chỉ `image/jpeg`, `image/png`, `image/webp` được
chấp nhận; kích thước tối đa là 5 MiB. Object key có dạng:

```text
uploads/<category>/<year>/<month>/<uuid>.<extension>
```

URL ký có thời hạn 15 phút. Object được gắn
`Cache-Control: public, max-age=31536000, immutable`.

## R2 CORS

CORS phải khai báo origin cụ thể của các frontend được phép upload. Không dùng
`*` hoặc wildcard `*.vercel.app` cho môi trường production. Ví dụ:

```json
[
  {
    "AllowedOrigins": [
      "https://tqs.vn",
      "https://tqsshop.vercel.app",
      "http://localhost:3000"
    ],
    "AllowedMethods": ["GET", "PUT", "HEAD"],
    "AllowedHeaders": ["Content-Type", "Cache-Control"],
    "ExposeHeaders": ["ETag"],
    "MaxAgeSeconds": 3600
  }
]
```

Nếu dùng một domain Preview cụ thể để kiểm thử, thêm đúng domain đó vào cả
`MEDIA_ALLOWED_ORIGINS` và R2 CORS trong thời gian staging, sau đó gỡ lại khi
release gate đóng.
