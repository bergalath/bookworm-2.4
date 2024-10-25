# bookworm-2.4
Docker image from Debian bookworm with Ruby 2.4 Rubygems 3.3.27 and bundler 2.3.17
- https://hub.docker.com/r/bergalath/bookworm-ruby

Shamelessly taken & mixed from
- https://github.com/docker-library/ruby/blob/a564feaaee4c8647c299ab11d41498468bb9af7b/2.4/buster/Dockerfile⁠
- https://github.com/docker-library/ruby/blob/master/3.1/bookworm/Dockerfile⁠

# Usage

- Dockerfile
  ```docker
  FROM bergalath/bookworm-ruby:2.4-2
  ```

- compose.yml
  ```yaml
  services:
    […]
      image: bergalath/bookworm-ruby:2.4-2
  ```

Then follow https://bundler.io/guides/bundler_docker_guide.html as usual
