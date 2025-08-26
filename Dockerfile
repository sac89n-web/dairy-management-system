FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENV ASPNETCORE_URLS=http://+:$PORT

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/Web/Dairy.Web.csproj", "src/Web/"]
RUN dotnet restore "src/Web/Dairy.Web.csproj"
COPY src/Web/ src/Web/
WORKDIR "/src/src/Web"
RUN dotnet build "Dairy.Web.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Dairy.Web.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Dairy.Web.dll"]