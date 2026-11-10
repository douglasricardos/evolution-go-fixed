FROM golang:1.25.0-alpine AS build
RUN apk add --no-cache git build-base python3 libjpeg-turbo-dev libwebp-dev
WORKDIR /build
# Usa a revisão da release 0.7.2 oficial
RUN git clone --depth 1 --branch 0.7.2 https://github.com/evolution-foundation/evolution-go.git . \
    && test "$(git rev-parse HEAD)" = "9337afc47e10b86cc896a6f432240e40fee95dd1"
# Aplica a versão configurada/detectada ao handshake do WhatsApp (PR #227)
RUN python3 -c 'from pathlib import Path; p=Path("pkg/whatsmeow/service/whatsmeow.go"); s=p.read_text(); anchor="\tminLevel := w.config.WaDebug"; patch="\tif version.Major > 0 && version.Minor > 0 && version.Patch > 0 {\n\t\tstore.SetWAVersion(store.WAVersionContainer{uint32(version.Major), uint32(version.Minor), uint32(version.Patch)})\n\t\tw.loggerWrapper.GetLogger(cd.Instance.Id).LogInfo(\"[%s] Applied WhatsApp handshake version: %s\", cd.Instance.Id, store.GetWAVersion().String())\n\t}\n\n"; assert s.count(anchor)==1, "Ponto de aplicacao do patch inesperado"; p.write_text(s.replace(anchor, patch+anchor))'
# Atualiza o whatsmeow para a primeira versão que confirma (ack) nós <status>.
# Sem isso o WhatsApp derruba a conexão a cada ~50 min com
# <stream:error><ack class="status" type="media"/> (evolution-go #211, PR #220).
RUN go get go.mau.fi/whatsmeow@v0.0.0-20260720135917-a2381054887e \
    && grep -q "go.mau.fi/whatsmeow v0.0.0-20260720135917-a2381054887e" go.mod
RUN gofmt -w pkg/whatsmeow/service/whatsmeow.go \
    && go mod download
RUN printf '0.7.2-fix405-statusack\n' > VERSION \
    && CGO_ENABLED=1 go build -ldflags "-X main.version=0.7.2-fix405-statusack" -o server ./cmd/evolution-go

FROM alpine:3.19.1
RUN apk add --no-cache ca-certificates tzdata ffmpeg libjpeg-turbo libwebp poppler-utils curl
WORKDIR /app
COPY --from=build /build/server .
COPY --from=build /build/manager/dist ./manager/dist
COPY --from=build /build/VERSION ./VERSION
ENV TZ=America/Sao_Paulo
EXPOSE 8080
ENTRYPOINT ["/app/server"]
