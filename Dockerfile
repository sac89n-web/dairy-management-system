FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY src/Domain/Domain.csproj src/Domain/
COPY src/Application/Application.csproj src/Application/
COPY src/Infrastructure/Infrastructure.csproj src/Infrastructure/
COPY src/Reports/Reports.csproj src/Reports/
COPY src/Web/Dairy.Web.csproj src/Web/

# Restore dependencies
RUN dotnet restore src/Web/Dairy.Web.csproj

# Copy source code
COPY src/ src/

# Build
RUN dotnet build src/Web/Dairy.Web.csproj -c Release -o /app/build

FROM build AS publish
RUN dotnet publish src/Web/Dairy.Web.csproj -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Environment variables for cloud deployment
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:$PORT

ENTRYPOINT ["dotnet", "Dairy.Web.dll"]