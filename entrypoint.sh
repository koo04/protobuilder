#!/bin/bash -e

printUsage() {
    echo "protobuilder simplifies the process to generate grpc code"
    echo " "
    echo "Usage: protobuilder -i ./rpc -f api/v1/service.proto -o ./src"
    echo " "
    echo "options:"
    echo " -h, --help                   Show this usage documentation"
    echo " -i                           The path to the *.proto files to generate"
    echo " -f                           The *.proto file to generate the code from"
    echo " -o                           The path to save the generated source code. All code generated will
                                        have a prefixed path of './internal/gen/proto/go'"
    echo " -v                           Output some verbose debug information"
    echo " --output-prefix-path         Using this will override the default '/internal/gen/proto/go' prefix for the 
                                        output path"
    echo " --asset-prefix-path          Using this will override the default '/assets/' prefix for the openapi path"
    echo " --grpc-api-configuration     The *.yaml file to configure the grpc gateway endpoints"
    echo " --openapi-configuration      A supplement file to build out the OpenAPIV2 *.swagger document"
    echo " --with-go                    Enables the output to generate the *.pb.go files"
    echo " --with-grpc                  Enables the output to generate the *_grpc.pb.go files"
    echo " --with-gateway               Enables the output to generate the *.pb.gw.go files"
    echo " --with-openapiv2             Enables the output to generate the *.swagger.json files"
    echo " --shell                      Drops you into shell prompt after execution"
}

INPUT_PATH=${INPUT_PATH}
OUTPUT_PATH=${OUTPUT_PATH}
PROTO_FILE=${PROTO_FILE}
OUTPUT_PREFIX_PATH="/internal/gen/proto/go"
ASSET_PREFIX_PATH="/assets/"
GRPC_API_CONFIGURATION=${GRPC_API_CONFIGURATION}
OPENAPI_CONFIGURATION=${OPENAPI_CONFIGURATION}
GEN_GO=${GEN_GO}
GEN_GO_GRPC=${GEN_GO_GRPC}
GEN_GRPC_GATEWAY=${GEN_GRPC_GATEWAY}
GEN_OPENAPIV2=${GEN_OPENAPIV2}
VERBOSE=false
SHELL=false

while test $# -gt 0; do
    case "$1" in
        -h|--help)
            printUsage
            exit 0
            ;;
        -i)
            shift
            if test $# -gt 0; then
                INPUT_PATH=$1
            else
                echo "no input path specified"
                exit 1
            fi
            shift
            ;;
        -f)
            shift
            if test $# -gt 0; then
                PROTO_FILE=$1
            else
                echo "no proto file specified"
                exit 1
            fi
            shift
            ;;
        -o)
            shift
            if test $# -gt 0; then
                OUTPUT_PATH=$1
            else
                echo "no output path specified"
                exit 1
            fi
            shift
            ;;
        -v) 
            VERBOSE=true
            shift
            ;;
        --with-go)
            GEN_GO=true
            shift
            ;;
        --with-grpc)
            GEN_GO_GRPC=true
            shift
            ;;
        --with-gateway)
            GEN_GRPC_GATEWAY=true
            shift
            ;;
        --with-openapiv2)
            GEN_OPENAPIV2=true
            shift
            ;;
        --output-prefix-path)
            shift
            if test $# -gt 0; then
                OUTPUT_PREFIX_PATH=$1
            else
                echo "no output prefix specified"
                exit 1
            fi
            shift
            ;;
        --asset-prefix-path)
            shift
            if test $# -gt 0; then
                ASSET_PREFIX_PATH=$1
            else
                echo "no asset path specified"
                exit 1
            fi
            shift
            ;;
        --grpc-api-configuration)
            shift
            if test $# -gt 0; then
                GRPC_API_CONFIGURATION=$1
            else
                echo "no grpc api configuration specified"
                exit 1
            fi
            shift
            ;;
        --openapi-configuration)
            shift
            if test $# -gt 0; then
                OPENAPI_CONFIGURATION=$1
            else
                echo "no openapi configuration specified"
                exit 1
            fi
            shift
            ;;
        --package-maps)
            shift
            if test $# -gt 0; then
                PACKAGE_MAPS=$1
            else
                echo "no package specified"
                exit 1
            fi
            shift
            ;;
        --shell) 
            SHELL=true
            shift

    esac
done

if [[ -z $INPUT_PATH && -z $OUTPUT_PATH && -z $PROTO_FILE ]]; then
    echo "Error: You must specify the proto directory, the source proto file, and the output path for the generated files"
    printUsage
    exit 1
fi

if [[ $GEN_GRPC_GATEWAY == true && -z $GRPC_API_CONFIGURATION ]]; then
    echo "Error: You must specify the grpc api configuration when generating gateway files"
    printUsage
    exit 1
fi

if [[ $GEN_OPENAPIV2 == true ]] && [[ ! ${GRPC_API_CONFIGURATION} || ! ${OPENAPI_CONFIGURATION} ]]; then
    echo "Error: You must specify the grpc api configuration when generating gateway files"
    printUsage
    exit 1
fi

OUTPUT_PATH=$(echo $OUTPUT_PATH | sed 's:/*$::')

GEN_GO_STRING=''
if [[ $GEN_GO == true ]]; then
    GEN_GO_STRING="--go_out ${OUTPUT_PATH}${OUTPUT_PREFIX_PATH} --go_opt paths=source_relative"
fi

GEN_GRPC_STRING=''
if [[ $GEN_GO_GRPC == true ]]; then
    GEN_GRPC_STRING="--go-grpc_out ${OUTPUT_PATH}${OUTPUT_PREFIX_PATH} --go-grpc_opt require_unimplemented_servers=false --go-grpc_opt paths=source_relative"
fi

GEN_GATEWAY_STRING=''
if [[ $GEN_GRPC_GATEWAY == true ]]; then
    GEN_GATEWAY_STRING="--grpc-gateway_out ${OUTPUT_PATH}${OUTPUT_PREFIX_PATH} --grpc-gateway_opt logtostderr=true --grpc-gateway_opt generate_unbound_methods=true --grpc-gateway_opt paths=source_relative --grpc-gateway_opt grpc_api_configuration=$GRPC_API_CONFIGURATION"
fi

GEN_OPENAPIV2_STRING=''
if [[ $GEN_OPENAPIV2 == true ]]; then
    GEN_OPENAPIV2_STRING="--openapiv2_out ${OUTPUT_PATH}${ASSET_PREFIX_PATH} --openapiv2_opt logtostderr=true --openapiv2_opt use_go_templates=true --openapiv2_opt grpc_api_configuration=$GRPC_API_CONFIGURATION --openapiv2_opt openapi_configuration=$OPENAPI_CONFIGURATION"
fi

GEN_PACKAGE_STRING=''
if [[ $PACKAGE_MAPS ]]; then
    readarray -d , -t package_maps <<< "$PACKAGE_MAPS"
    for package_map in "${package_maps[@]}"; do
    
        if [[ $GEN_GO == true ]]; then
            GEN_PACKAGE_STRING="$GEN_PACKAGE_STRING --go_opt M$package_map"
        fi

        if [[ $GEN_GO_GRPC == true ]]; then
            GEN_PACKAGE_STRING="$GEN_PACKAGE_STRING --go-grpc_opt M$package_map"
        fi

        if [[ $GEN_GRPC_GATEWAY == true ]]; then
            GEN_PACKAGE_STRING="$GEN_PACKAGE_STRING --grpc-gateway_opt M$package_map"
        fi
        
        if [[ $GEN_OPENAPIV2 == true ]]; then
            GEN_PACKAGE_STRING="$GEN_PACKAGE_STRING --openapiv2_opt M$package_map"
        fi
        
    done
fi

# Enter the working directory
cd /app

mkdir -p ${OUTPUT_PATH}${OUTPUT_PREFIX_PATH}
mkdir -p ${OUTPUT_PATH}${ASSET_PREFIX_PATH}

if [[ $VERBOSE == true ]]; then
    echo "input: ${INPUT_PATH}"
    echo "output: ${OUTPUT_PATH}"
    echo "file: ${PROTO_FILE}"
    echo "grpc api configuration: ${GRPC_API_CONFIGURATION}"
    echo "openapi configuration: ${OPENAPI_CONFIGURATION}"
    echo "gen-go: ${GEN_GO}"
    echo "gen-go-grpc: ${GEN_GO_GRPC}"
    echo "gen-grpc-gateway: ${GEN_GRPC_GATEWAY}"
    echo "gen-openapiv2: ${GEN_OPENAPIV2}"
    echo "shell: ${SHELL}" 
    printf "protoc -I $INPUT_PATH \n\
        $GEN_GO_STRING \n\
        $GEN_GRPC_STRING \n\
        $GEN_GATEWAY_STRING \n\
        $GEN_OPENAPIV2_STRING \n\
        $GEN_PACKAGE_STRING \n\
        $PROTO_FILE\n"
fi

# run protoc
protoc -I $INPUT_PATH \
    $GEN_GO_STRING \
    $GEN_GRPC_STRING \
    $GEN_GATEWAY_STRING \
    $GEN_OPENAPIV2_STRING \
    $GEN_PACKAGE_STRING \
    $PROTO_FILE

echo "Completed $PROTO_FILE"

if [[ $SHELL == true ]]; then
    /bin/bash
fi
