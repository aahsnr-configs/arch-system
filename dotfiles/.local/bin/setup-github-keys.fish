echo "Setting up SSH keys for multiple GitHub accounts..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

function generate_key --argument key_name email
    set -l key_path "$HOME/.ssh/id_rsa_$key_name"

    if not test -f "$key_path"
        echo "Generating RSA 4096 SSH key for '$key_name'..."
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$key_path" -N ""
        chmod 600 "$key_path"
        chmod 644 "$key_path.pub"
        echo "-> Generated key: $key_path"
    else
        echo "-> Key for '$key_name' already exists: $key_path"
    end
end

generate_key "aahsnr_configs" "ahsanur041@proton.me"
generate_key "aahsnr_personal" "ahsanur041@gmail.com"
generate_key "aahsnr_work" "aahsnr041@proton.me"
generate_key "aahsnr_common" "ahsan.05rahman@gmail.com"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next Steps:"
echo "1. Add the public keys to your respective GitHub accounts:"
echo "   - Configs:  cat ~/.ssh/id_rsa_aahsnr_configs.pub"
echo "   - Personal: cat ~/.ssh/id_rsa_aahsnr_personal.pub"
echo "   - Work:     cat ~/.ssh/id_rsa_aahsnr_work.pub"
echo "   - Common:   cat ~/.ssh/id_rsa_aahsnr_common.pub"
echo ""
echo "2. Authenticate each account with the GitHub CLI (run these one by one):"
echo "   gh auth login --hostname github.com"
echo "   (You will need to do this for each of your accounts)"
echo ""
echo "3. Test your SSH connections:"
echo "   ssh -T git@github.com-aahsnr-configs"
echo "   ssh -T git@github.com-aahsnr-personal"
echo "   ssh -T git@github.com-aahsnr-work"
echo "   ssh -T git@github.com-aahsnr-common"
echo ""
echo "4. Create your project directories:"
echo "   mkdir -p ~/git-repos/configs ~/git-repos/personal ~/git-repos/work ~/git-repos/common"
