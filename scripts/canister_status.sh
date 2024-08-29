#!/usr/bin/expect -f

set timeout -1

# Obtener la contraseña de la variable de entorno
set passphrase $env(INTERNET_IDENTITY_PASSPHRASE)

# Desbloquear la identidad
spawn dfx identity use cerotrade
expect {
    "Please enter the passphrase for your identity:" {
        send "$passphrase\r"
        exp_continue
    }
    eof
}

# Función para obtener el balance de cycles del canister
proc get_canister_balance {canister_name passphrase} {
    puts "====-$canister_name-===="
    spawn dfx canister status $canister_name --network ic
    expect {
        "Please enter the passphrase for your identity:" {
            send "$passphrase\r"
            exp_continue
        }
        eof
    }
}

# Llamar a la función para cada canister
set canisters {cero_trade_project_frontend agent http_service user_index token_index notification_index transaction_index bucket_index marketplace statistics}

foreach canister $canisters {
    get_canister_balance $canister $passphrase
}
