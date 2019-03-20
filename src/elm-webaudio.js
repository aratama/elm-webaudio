import createVirtualAudioGraph from 'virtual-audio-graph';
import {
    analyser,
    bufferSource,
    biquadFilter,
    channelMerger,
    channelSplitter,
    convolver,
    delay,
    dynamicsCompressor,
    gain,
    mediaElementSource,
    mediaStreamDestination,
    mediaStreamSource,
    oscillator,
    panner,
    stereoPanner,
    waveShaper
} from 'virtual-audio-graph';

customElements.define(
    "elm-webaudio",
    class extends HTMLElement {
        constructor() {
            super();
            this.virtualAudioGraph = createVirtualAudioGraph();
            this.audioGraphJson = [];
            this.audioBufferMap = new Map();
            this.timerEnabled = true;
            this.wait = 40;
            const start = () => {
                const event = new CustomEvent("tick", { detail: this.virtualAudioGraph.currentTime });
                this.dispatchEvent(event);
                if (this.timerEnabled) {
                    setTimeout(start, this.wait);
                }
            }
            start();
        }

        set graph(value) {
            this.audioGraphJson = value;
            this.virtualAudioGraph.update(this.jsonToVirtualWebAudioGraph(value));
        }

        set assets(value) {
            for (let url of value) {
                this.getAudioBuffer(url);
            }
        }

        connectedCallback() {
            this.virtualAudioGraph.update({});
        }

        disconnectedCallback() {
            this.timerEnabled = false;
        }

        jsonToVirtualWebAudioGraph(json) {
            const vgraph = {};
            Object.keys(json).forEach(key => {
                const jnode = json[key];
                switch (jnode.node) {
                    case "Analyser":
                        vgraph[key] = analyser(jnode.output, {
                            fftSize: jnode.fftSize,
                            minDecibels: jnode.minDecibels,
                            maxDecibels: jnode.maxDecibels,
                            smoothingTimeConstant: jnode.smoothingTimeConstant
                        });
                        break;
                    case "BufferSource":
                        vgraph[key] = bufferSource(jnode.output, {
                            buffer: this.getAudioBuffer(jnode.buffer),
                            startTime: jnode.startTime,
                            stopTime: jnode.stopTime,
                            detune: jnode.detune
                        });
                        break;
                    case "BiquadFilter":
                        vgraph[key] = biquadFilter(jnode.output, {
                            type: jnode.type,
                            frequency: jnode.frequency,
                            detune: jnode.detune,
                            Q: jnode.Q
                        });
                        break;
                    case "ChannelMerger":
                        vgraph[key] = channelMerger(jnode.output, {});
                        break;
                    case "ChannelSplitter":
                        vgraph[key] = channelSplitter(jnode.output, {});
                        break;
                    case "Convolver":
                        vgraph[key] = convolver(jnode.output, { buffer: this.getAudioBuffer(jnode.buffer) });
                        break;
                    case "Delay":
                        vgraph[key] = delay(jnode.output, { delayTime: jnode.delayTime });
                        break;
                    case "DynamicsCompressor":
                        vgraph[key] = dynamicsCompressor(jnode.output, { buffer: this.getAudioBuffer(jnode.buffer) });
                        break;
                    case "Gain":
                        vgraph[key] = gain(jnode.output, { gain: jnode.gain });
                        break;
                    case "MediaElementSource":
                        vgraph[key] = mediaElementSource(jnode.output, { mediaElement: document.getElementById(jnode.mediaElement) });
                        break;
                    case "MediaStreamDestination":
                        vgraph[key] = mediaStreamDestination(jnode.output, {});
                        break;
                    case "MediaStreamSource":
                        vgraph[key] = mediaStreamSource(jnode.output, { mediaStream: jnode.mediaStream });
                        break;
                    case "Oscillator":
                        vgraph[key] = oscillator(jnode.output, { type: "sine", frequency: jnode.frequency, detune: 0, startTime: jnode.startTime, stopTime: jnode.stopTime });
                        break;
                    case "Panner":
                        vgraph[key] = panner(output, {
                            coneInnerAngle: jnode.coneInnerAngle,
                            coneOuterAngle: jnode.coneOuterAngle,
                            coneOuterGain: jnode.coneOuterGain,
                            distanceModel: jnode.distanceModel,
                            orientation: [jnode.orientatonX, jnode.orientationY, jnode.orientationZ],
                            panningModel: jnode.pannerModel,
                            position: [jnode.positionX, jnode.positionY, jnode.positionZ],
                            maxDistance: jnode.maxDistance,
                            refDistance: jnode.refDistance,
                            rolloffFactor: jnode.rolloffFactor,
                        });
                        break;
                    case "StereoPanner":
                        vgraph[key] = stereoPanner(output, { pan: jnode.pan })
                        break;
                    case "WaveShaper":
                        vgraph[key] = waveShaper(output, {
                            curve: Float32Array.from(jnode.curve),
                            oversample: jnode.oversample
                        })
                        break;
                    default:
                        debugger;
                        throw new Error("Unsupported audio node: " + json.node);
                }
            });
            return vgraph;
        }

        getAudioBuffer(url) {
            const buffer = this.audioBufferMap.get(url);
            if (!url) {
                return null;
            } else if (!this.virtualAudioGraph) {
                return null;
            } else if (buffer === "loading") {
                return null;
            } else if (buffer) {
                return buffer;
            } else {
                this.audioBufferMap.set(url, "loading");
                fetch(url).then(response => {
                    return response.arrayBuffer().then(arrayBuffer => {
                        return this.virtualAudioGraph.audioContext.decodeAudioData(arrayBuffer).then(decoded => {
                            this.audioBufferMap.set(url, decoded);
                            this.virtualAudioGraph.update(this.jsonToVirtualWebAudioGraph(this.audioGraphJson));
                        });
                    });
                }).catch(err => {
                    console.error(url + err);
                });
                return null;
            }
        }
    }
);
