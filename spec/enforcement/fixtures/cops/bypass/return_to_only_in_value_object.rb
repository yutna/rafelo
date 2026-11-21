# expected offenses: 3
params[:return_to]
params.dig(:return_to, :fallback)
request.params[:return_to]
note = "return_to" # params[:return_to] in a comment
"params.fetch(:return_to)"
