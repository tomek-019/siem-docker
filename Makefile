WAZUH_DIR           := wazuh-docker/single-node
JUICE_DIR           := juiceshop-docker

WAZUH_COMPOSE_FILE  := $(WAZUH_DIR)/docker-compose.yml
JUICE_COMPOSE_FILE  := $(JUICE_DIR)/docker-compose.yml

CERTS_COMPOSE       := $(WAZUH_DIR)/generate-indexer-certs.yml
CERTS_DIR           := $(WAZUH_DIR)/config/wazuh_indexer_ssl_certs
CERTS_DONE          := $(WAZUH_DIR)/.certs-generated

WAZUH_COMPOSE       := docker compose -f $(WAZUH_COMPOSE_FILE)
JUICE_COMPOSE       := docker compose -f $(JUICE_COMPOSE_FILE)

.PHONY: help up down clean certs logs restart

help:
	@echo "make up       - wygeneruj certy (jeśli brak) i postaw stack"
	@echo "make down     - zatrzymaj kontenery (certy i dane zostają)"
	@echo "make clean    - usuń kontenery, wolumeny ORAZ certy (WYMAGA SUDO)"
	@echo "make logs     - pokaż logi na żywo"
	@echo "make restart  - down + up"

certs:
	@if [ ! -f "$(CERTS_DONE)" ]; then \
		echo ">> Katalog certyfikatow pusty - generuję certyfikaty..."; \
		docker compose -f $(CERTS_COMPOSE) run --rm generator; \
		touch $(CERTS_DONE); \
	else \
		echo ">> Certyfikaty już istnieją, pomijam."; \
	fi

up: certs
	@echo ">> Sprawdzam vm.max_map_count..."
	@if [ "$$(sysctl -n vm.max_map_count)" -lt 262144 ]; then \
		echo ">> vm.max_map_count jest mniejsze niż 262144. Zmien za pomoca: sudo sysctl -w vm.max_map_count=262144"; \
		exit 1; \
	fi
	@echo ">> Stawiam stack..."
	$(WAZUH_COMPOSE) up -d
	@echo ">> Stawiam juiceshop..."
	$(JUICE_COMPOSE) up -d
	@echo ">> Wazuh dashboard: https://localhost (admin / SecretPassword)"
	@echo ">> Juiceshop: http://localhost:3000"

down:
	$(WAZUH_COMPOSE) down
	$(JUICE_COMPOSE) down

clean:
	$(WAZUH_COMPOSE) down -v
	@echo ">> Usuwam certyfikaty..."
	rm -rf $(CERTS_DIR)
	rm -f $(CERTS_DONE)

logs:
	$(WAZUH_COMPOSE) logs -f

restart: down up
